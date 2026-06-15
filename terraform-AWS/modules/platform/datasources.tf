# data "aws_iam_policy_document" "ec2_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     effect  = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }

# data "aws_iam_policy" "aws_ssm_core_policy" {
#   name = "AmazonSSMManagedInstanceCore"
# }

# 신뢰 관계(Trust Relationship) 정의
data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["dms.amazonaws.com"]
    }
  }
}

data "aws_secretsmanager_secret_version" "db_password" {
  # RDS 리소스가 생성한 secret_arn을 정확히 지정
  secret_id = aws_db_instance.petclinic_db.master_user_secret[0].secret_arn
}