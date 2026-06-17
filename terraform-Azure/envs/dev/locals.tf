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

  # vpn = {
  #   tunnel1_ip = data.terraform_remote_state.aws_vpn.vpn_tunnel1_outside_ip
  #   tunnel2_ip = data.terraform_remote_state.aws_vpn.vpn_tunnel2_outside_ip
  #   tunnel1_key = data.terraform_remote_state.aws_vpn.vpn_tunnel1_preshared_key
  #   tunnel2_key = data.terraform_remote_state.aws_vpn.vpn_tunnel2_preshared_key
  # }
}
