variable "namespace" {
  type = string
}

variable "azure_private_dns_resolver_inbound_ips" {
  type        = list(string)
  description = "Azure DNS Private Resolver inbound endpoint IPs reached over the AWS-to-Azure VPN."
  default     = []
}

variable "azure_vnet_cidr" {
  type        = string
  description = "Azure VNet CIDR reached over the AWS VPN gateway."
  default     = null
}

variable "azure_vpn_gateway_id" {
  type        = string
  description = "AWS virtual private gateway ID for routes to Azure."
  default     = null
}
