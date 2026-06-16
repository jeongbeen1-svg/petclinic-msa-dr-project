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
      gateway_ip_address         = "43.203.69.72"
      shared_key                 = "8X.PB9fVikchxcGvnJjgRl_H_p9VoQ.Z"
    }
    tunnel-2 = {
      local_network_gateway_name = "local-networ-gw-tunnel-test-2"
      connection_name            = "vpn-conn2"
      gateway_ip_address         = "52.78.32.238"
      shared_key                 = "y2PyoX0bvLg0aB.FtjiIx3GqVmPDbuxf"
    }
  }
}
