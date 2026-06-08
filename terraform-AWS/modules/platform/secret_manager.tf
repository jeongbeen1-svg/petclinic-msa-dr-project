# # 비밀번호 보관함 생성
# resource "aws_secretsmanager_secret" "db_password" {
#   name = "${local.namespace}-db-password"
# }

# # 실제 비밀번호 값 등록
# resource "aws_secretsmanager_secret_version" "db_password_version" {
#   secret_id     = aws_secretsmanager_secret.db_password.id
#   secret_string = jsonencode({
#     username = "admin"
#     password = "data1234!"
#   })
# }