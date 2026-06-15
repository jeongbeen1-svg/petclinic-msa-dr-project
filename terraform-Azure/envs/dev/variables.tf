variable "db_username" {
  type        = string
  description = "Azure MySQL administrator username"
  default     = "petclinicadmin"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Azure MySQL administrator password"
}

variable "bastion_allowed_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH to the Azure bastion VM"
  default     = [
                  "58.72.80.6/32"
                , "1.212.30.179/32" # 6층 IP
                ]
}

variable "aws_vpn_tunnel1_preshared_key" {
  type        = string
  description = "Pre-shared key for Azure-to-AWS VPN tunnel 1."
  sensitive   = true
}

variable "aws_vpn_tunnel2_preshared_key" {
  type        = string
  description = "Pre-shared key for Azure-to-AWS VPN tunnel 2."
  sensitive   = true
}

variable "aws_vpn_tunnel1_preshared_key" {
  type        = string
  description = "Pre-shared key for Azure-to-AWS VPN tunnel 1."
  sensitive   = true
}

variable "aws_vpn_tunnel2_preshared_key" {
  type        = string
  description = "Pre-shared key for Azure-to-AWS VPN tunnel 2."
  sensitive   = true
}
