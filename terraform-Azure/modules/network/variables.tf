variable "namespace" {
  type = string
}

variable "location" {
  type = string
}

variable "aws_vpc_cidr" {
  type        = string
  description = "AWS VPC CIDR reachable through the site-to-site VPN."
  default     = "172.31.0.0/16"
}

variable "aws_vpn_tunnels" {
  type = map(object({
    local_network_gateway_name = string
    connection_name            = string
    gateway_ip_address         = string
    shared_key                 = optional(string)
  }))
  description = "AWS VPN tunnel definitions for Azure local network gateways and connections."
  default     = {}
}
