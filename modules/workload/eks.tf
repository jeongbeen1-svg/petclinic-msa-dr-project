# 1. EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name = "${local.namespace}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
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
    endpoint_private_access = true  # 실무 필수: 내부 보안망 강화
    endpoint_public_access  = true  # 개발 편의상 퍼블릭 오픈 (WSL 접속용)
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
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

# 4. 기본 관리용 시스템 Node Group (카펜터가 구동되기 위한 기본 뼈대 노드 2대)
resource "aws_iam_role" "node" {
  name = "${local.namespace}-eks-node-role"

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
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy", # EC2 인스턴스가 출근할 수 있게 함
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy", # 내부 파드에 IP 분배, 통신 가능하게 함
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", # 노드가 ECR에 접근해서 이미지 다운로드할 수 있게 함
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" # 베스천 없이 파드 접속용 SSM 권한
  ])
  policy_arn = each.value
  role       = aws_iam_role.node.name
}

resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${local.namespace}-node-template"

  # 매우 중요: EC2 인스턴스가 켜질 때 'Name' 태그를 명시적으로 지정
  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, {
      Name = "${local.namespace}-eks-system-node"
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
    desired_size = 1
    max_size     = 3
    min_size     = 0
  }

  instance_types = ["t3.medium"]

  # 템플릿을 노드 그룹에 연결
  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  # 노드 그룹 자체에도 태그를 유지
  tags = merge(local.common_tags, {
    Name = "${local.namespace}-eks-node-group"
  })

  depends_on = [aws_iam_role_policy_attachment.node_policies]
}