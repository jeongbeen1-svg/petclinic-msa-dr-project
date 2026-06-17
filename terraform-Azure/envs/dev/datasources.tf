# AWS 환경 상태파일에서의 값 추출
# data "terraform_remote_state" "aws_infra" {
#   backend = "s3"
#   config = {
#     bucket = "tf-core-aws-tfstate"
#     key    = "dev/aws/terraform.tfstate"
#     region = "ap-northeast-2"
#   }
# }