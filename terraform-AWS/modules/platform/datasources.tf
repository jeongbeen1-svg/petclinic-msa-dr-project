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

# 람다 파일 관련 코드
data "archive_file" "lambda_backup_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_backup"
  output_path = "${path.module}/lambda_backup.zip"
}
# 람다 파일 관련 코드
data "archive_file" "lambda_transfer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_transfer"
  output_path = "${path.module}/lambda_transfer.zip"
}

# # Lambda Layer (pymysql 라이브러리)
data "archive_file" "lambda_layer" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_layer"
  output_path = "${path.module}/lambda_layer.zip"
}