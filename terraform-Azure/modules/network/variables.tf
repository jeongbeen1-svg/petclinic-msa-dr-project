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
      gateway_ip_address         = "54.116.15.231"
      shared_key                 = "AZjJGmzJesq5VZ7U8hTA0SUts998dSvM"
    }
    tunnel-2 = {
      local_network_gateway_name = "local-networ-gw-tunnel-test-2"
      connection_name            = "vpn-conn2"
      gateway_ip_address         = "54.116.76.155"
      shared_key                 = "LQ6Yx_l7qfxzV8IV.06GTroZ0Fz3ISeu"
    }
  }
}
