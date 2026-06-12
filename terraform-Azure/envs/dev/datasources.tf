data "terraform_remote_state" "aws" {
  backend = "s3"

  config = {
    bucket       = "tf-core-tfstate-jaebok1205"
    key          = "dev/test/terraform.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
