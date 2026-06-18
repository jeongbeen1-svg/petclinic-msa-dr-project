data "aws_caller_identity" "current" {}

data "aws_arn" "caller" {
  arn = data.aws_caller_identity.current.arn
}

# Azure의 Remote State를 데이터 소스로 정의
data "terraform_remote_state" "azure" {
  backend = "azurerm"
  config = {
    resource_group_name  = "ej-terraform-state"
    storage_account_name = "sttfstateej"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}