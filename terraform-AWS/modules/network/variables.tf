variable "namespace" {
  type = string
}

variable "azure_vpn_gateway_public_ip" {
  type    = string
  default = ""
}

variable "azure_ip_cidr_block" {
  type    = string
  default = ""
}