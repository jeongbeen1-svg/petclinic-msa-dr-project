locals {
  org         = "tf-core"
  project     = "test-1"
  environment = "dev"
  location    = "koreacentral"

  namespace = "${local.org}-${local.project}-${local.environment}"

  aws_vpc_cidr = "172.31.0.0/16"

  rds = {
    db_username = "petclinicadmin"
    db_password = "data1234!"
  }
}
