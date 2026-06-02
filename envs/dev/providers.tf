terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # [부트스트랩 전략]: 최초 1회는 이 backend 블록을 주석 처리하고 로컬에서 apply 한 뒤,
  # 생성된 S3/DynamoDB 정보 채워 넣고 주석 풀고 init 하시면 원격 마이그레이션이 완료
  backend "s3" {
    bucket       = "tf-core-ej-tfstate"
    key          = "dev/test/terraform.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "ap-northeast-2"

  default_tags {
    tags = {
      Organization = local.org
      Project      = local.project
      ManagedBy    = "Terraform"
    }
  }
}