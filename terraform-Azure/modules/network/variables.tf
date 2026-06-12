variable "namespace" {
  type = string
}

variable "location" {
  type = string
}

variable "aws_vpc_cidr" {
  type        = string
  description = "AWS VPC CIDR reachable through the site-to-site VPN."
}

variable "aws_vpn_tunnels" {
  type = map(object({
    local_network_gateway_name = string
    connection_name            = string
    gateway_ip_address         = string
    shared_key                 = optional(string)
  }))
  description = "AWS VPN tunnel definitions for Azure local network gateways and connections."
  default = {
    tunnel-1 = {
      local_network_gateway_name = "local-networ-gw-tunnel-test-1"
      connection_name            = "vpn-conn"
      gateway_ip_address         = "13.209.63.117"
      shared_key                 = "qhExyyB7AGgY9F7g9mjGvlx5.rq7YVf."
    }
    tunnel-2 = {
      local_network_gateway_name = "local-networ-gw-tunnel-test-2"
      connection_name            = "vpn-conn2"
      gateway_ip_address         = "43.202.152.118"
      shared_key                 = "m1vhdEXBbWP7bmu5MPKoHaBs98ObOCGA"
    }
  }
}
