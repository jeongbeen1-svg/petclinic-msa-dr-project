data "aws_caller_identity" "current" {}

data "terraform_remote_state" "azure" {
  backend = "local"

  config = {
    path = "/home/jaebok1205/test/terraform-Azure/envs/dev/terraform.tfstate"
  }
}

data "aws_arn" "caller" {
  arn = data.aws_caller_identity.current.arn
}
