# 최신 Amazon Linux 2023 AMI 자동 조회
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# External Secrets용 IAM 정책 정의
data "aws_iam_policy_document" "external_secrets" {
  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = ["*"] # 특정 시크릿만 허용하려면 해당 시크릿의 ARN을 넣으세요
  }
}