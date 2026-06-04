# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name = "${local.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })

  tags = { Name = "${local.cluster_name}-cluster-role" }
}

# EKS 클러스터용 보안 그룹 (컨트롤 플레인)
resource "aws_security_group" "eks_cluster" {
  name        = "${local.cluster_name}-cluster-sg"
  vpc_id      = var.vpc_id
  description = "EKS Cluster Control Plane SG"

  # Bastion으로부터의 443 포트 접근 허용
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] # Bastion 보안 그룹 ID를 참조
    description     = "Allow Bastion to access EKS API"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.cluster_name}-cluster-sg" }
}

# 노드용 보안 그룹 (데이터 플레인)
resource "aws_security_group" "eks_nodes" {
  name        = "${local.cluster_name}-node-sg"
  vpc_id      = var.vpc_id
  description = "EKS Node SG"

  # 노드 간 통신
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # 컨트롤 플레인 → 노드
  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    description     = "mgmt kubectl access"
  }

  # MGMT -> NodePort 인바운드 그룹
  ingress {
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] # Bastion 보안 그룹 ID를 참조
    description     = "mgmt NodePort access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.cluster_name}-node-sg" }
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# 2. EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = true # 실무 필수: 내부 보안망 강화
    endpoint_public_access  = true # 개발 편의상 퍼블릭 오픈 (WSL 접속용)
  }

  # API와 ConfigMap 방식을 둘 다 지원하도록 설정
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # 클러스터 로그 활성화
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}

# mgmt role 등 kubectl 접근 허용
resource "aws_eks_access_entry" "admin" {
  cluster_name = aws_eks_cluster.main.name

  for_each      = toset(local.all_admin_arns)
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name = aws_eks_cluster.main.name

  for_each      = toset(local.all_admin_arns)
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# 3. OIDC Provider 생성 (IRSA 보안용)
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# EKS node role
resource "aws_iam_role" "node" {
  name = "${local.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",          # EC2 인스턴스가 출근할 수 있게 함
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",               # 내부 파드에 IP 분배, 통신 가능하게 함
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", # 노드가 ECR에 접근해서 이미지 다운로드할 수 있게 함
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",       # 베스천 없이 파드 접속용 SSM 권한
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ])
  policy_arn = each.value
  role       = aws_iam_role.node.name
}

resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${local.cluster_name}-node-template"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.eks_nodes.id]
  }

  # 매우 중요: EC2 인스턴스가 켜질 때 'Name' 태그를 명시적으로 지정
  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, {
      Name = "${local.cluster_name}-system-node"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "system-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 0
  }

  instance_types = ["t3.large"]

  # 템플릿을 노드 그룹에 연결
  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  # 노드 그룹 자체에도 태그를 유지
  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-node-group"
  })

  # 업데이트나 생성 시 순서 보장
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_iam_role_policy_attachment.node_policies]
}

# ALB Ingress Controller용 인라인 정책
resource "aws_iam_role_policy" "node_alb" {
  name = "${local.cluster_name}-node-alb-policy"
  role = aws_iam_role.node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]
        Resource = "*"
      }
    ]
  })
}