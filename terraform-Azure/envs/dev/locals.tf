locals {
  org         = "tf-core-jaebok1205"
  project     = "test"
  environment = "dev"
  location    = "koreacentral"

  namespace = "${local.org}-${local.project}-${local.environment}"

  # 일단은 데베 테스트만 진행하실 떄는 0.0.0.0으로 설정하고 진행해주세요
  dms_ip = "본인의 DMS 복제 인스턴스 퍼블릭 주소를 입력"
  my_ip  = "본인의 IP 주소를 입력"

  aws_vpn = {
    vpc_cidr = "172.31.0.0/16"
    tunnels = {
      tunnel-1 = {
        local_network_gateway_name = "local-networ-gw-tunnel-1"
        connection_name            = "vpn-conn"
        gateway_ip_address         = data.terraform_remote_state.aws.outputs.module.network.azure_vpn.tunnel1_address
        shared_key                 = var.aws_vpn_tunnel1_preshared_key
      }
      tunnel-2 = {
        local_network_gateway_name = "local-networ-gw-tunnel-2"
        connection_name            = "vpn-conn2"
        gateway_ip_address         = data.terraform_remote_state.aws.outputs.module.network.azure_vpn.tunnel2_address
        shared_key                 = var.aws_vpn_tunnel2_preshared_key
      }
    }
  }
}
