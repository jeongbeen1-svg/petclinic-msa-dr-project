# # Lambda용 보안 그룹 (RDS 접근용)
# resource "aws_security_group" "lambda_sg" {
#   name   = "${var.namespace}-lambda_sg"
#   vpc_id = var.vpc_id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # 람다가 완전히 삭제된 후에 보안 그룹이 삭제되도록 의존성 주입
#   depends_on = [aws_lambda_function.dr_transfer]

#   tags = { Name = "${var.namespace}-lambda_sg" }
# }

# # 람다용 IAM 역할 (람다가 S3와 통신할 권한)
# resource "aws_iam_role" "lambda_exec" {
#   name = "${var.namespace}-lambda_exec_role"
#   assume_role_policy = jsonencode({
#     Version   = "2012-10-17"
#     Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
#   })
# }

# # S3 접근 권한 정책 (읽기 + 쓰기)
# resource "aws_iam_role_policy" "lambda_s3_policy" {
#   name = "${var.namespace}-lambda_s3_policy"
#   role = aws_iam_role.lambda_exec.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:ListBucket"
#         ]
#         Resource = [
#           "arn:aws:s3:::${var.s3_bucket_name}",
#           "arn:aws:s3:::${var.s3_bucket_name}/*"
#         ]
#       }
#     ]
#   })
# }

# # CloudWatch Logs 권한 (Lambda가 로그를 남길 수 있도록)
# resource "aws_iam_role_policy" "lambda_logs_policy" {
#   name = "${var.namespace}-lambda_logs_policy"
#   role = aws_iam_role.lambda_exec.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ]
#         Resource = "arn:aws:logs:*:*:*"
#       }
#     ]
#   })
# }

# # VPC 내 Lambda 실행 권한 (ENI 생성)
# # 이 방식이 삭제를 지연시키는 원인이라서 추후에 rds proxy 사용 등 다른 방식 사용 권장
# resource "aws_iam_role_policy" "lambda_vpc_policy" {
#   name = "${var.namespace}-lambda_vpc_policy"
#   role = aws_iam_role.lambda_exec.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:CreateNetworkInterface",
#           "ec2:DescribeNetworkInterfaces",
#           "ec2:DeleteNetworkInterface"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# # 람다 함수 정의
# resource "aws_lambda_function" "dr_transfer" {
#   filename      = data.archive_file.lambda_zip.output_path # 파이썬 코드를 zip으로 묶어서 업로드
#   function_name = "s3_to_azure_transfer"
#   role          = aws_iam_role.lambda_exec.arn
#   handler       = "lambda_function.lambda_handler"
#   runtime       = "python3.9"
#   timeout       = 30
#   memory_size   = 256

#   # zip 파일이 변경될 때마다 람다를 업데이트하도록 해줌
#   source_code_hash = data.archive_file.lambda_zip.output_base64sha256

#   # Lambda 환경변수 (RDS 연결 정보)
#   environment {
#     variables = {
#       RDS_ENDPOINT = aws_db_instance.petclinic_db.address
#       RDS_USER     = aws_db_instance.petclinic_db.username
#       RDS_PASSWORD = aws_db_instance.petclinic_db.password
#       RDS_DATABASE = "petclinic" # 사용할 데이터베이스 이름 (기존 DB 이름으로 변경하세요)
#       RDS_PORT     = "3306"
#       S3_BUCKET    = var.s3_bucket_name
#     }
#   }

#   # Lambda를 VPC 내에 배치 (RDS 접근 가능하게)
#   # vpc에 넣지 않는 방법을 찾아야 할 듯
#   # 일단은 이거 없어서 작동은 안 됨
#   # vpc_config {
#   #   subnet_ids         = var.private_subnet_ids
#   #   security_group_ids = [aws_security_group.lambda_sg.id]
#   # }

#   # Lambda Layer (pymysql 라이브러리)
#   layers = [aws_lambda_layer_version.python_deps.arn]
# }

# # Lambda Layer 버전
# resource "aws_lambda_layer_version" "python_deps" {
#   filename            = data.archive_file.lambda_layer.output_path
#   layer_name          = "${var.namespace}-python-deps"
#   compatible_runtimes = ["python3.9"]
#   source_code_hash    = data.archive_file.lambda_layer.output_base64sha256

#   depends_on = [data.archive_file.lambda_layer]
# }

# # CloudWatch Events 추가
# resource "aws_cloudwatch_event_rule" "rds_backup" {
#   name                = "${var.namespace}-rds_backup_daily"
#   description         = "RDS 데이터를 매일 S3에 백업"
#   # 현재 3분마다 백업 생성되도록 설정 (수동 lambda 트리거 가능하므로 수정해도 됨)
#   schedule_expression = "cron(0/3 * * * ? *)"
# }

# resource "aws_cloudwatch_event_target" "lambda_target" {
#   rule      = aws_cloudwatch_event_rule.rds_backup.name
#   target_id = "RDSBackupLambda"
#   arn       = aws_lambda_function.dr_transfer.arn
# }

# resource "aws_lambda_permission" "allow_cloudwatch" {
#   statement_id  = "AllowExecutionFromCloudWatch"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.dr_transfer.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.rds_backup.arn

#   depends_on = [aws_lambda_function.dr_transfer]
# }