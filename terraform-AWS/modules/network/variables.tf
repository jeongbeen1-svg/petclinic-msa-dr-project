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

variable "azure_customer_gateway_ip_address" {
  type        = string
  description = "Azure VPN gateway public IP address used as the AWS customer gateway."
  default     = null
}

variable "azure_vpn_tunnel1_preshared_key" {
  type        = string
  description = "Pre-shared key for AWS-to-Azure VPN tunnel 1."
  sensitive   = true
  default     = null
}

variable "azure_vpn_tunnel2_preshared_key" {
  type        = string
  description = "Pre-shared key for AWS-to-Azure VPN tunnel 2."
  sensitive   = true
  default     = null
}
