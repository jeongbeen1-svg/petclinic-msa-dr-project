variable "additional_admin_arns" {
  description = <<-EOT
    aws-auth ConfigMap에 system:masters로 추가할 IAM Role/User ARN 목록.
    terraform apply 실행 계정(임시 ARN 포함)은 자동으로 추가되므로
    추가 팀원 Role ARN만 여기에 지정하면 됩니다.

    예시:
      additional_admin_arns = [
        "arn:aws:iam::123456789012:role/DevOpsAdminRole",
        "arn:aws:iam::123456789012:role/CICDRole",
      ]
  EOT
  type        = list(string)
  default     = []
}

variable "azure_vpn_tunnel1_preshared_key" {
  type        = string
  description = "Pre-shared key for AWS-to-Azure VPN tunnel 1. Existing imported VPN connections ignore key drift."
  sensitive   = true
  default     = null
}

variable "azure_vpn_tunnel2_preshared_key" {
  type        = string
  description = "Pre-shared key for AWS-to-Azure VPN tunnel 2. Existing imported VPN connections ignore key drift."
  sensitive   = true
  default     = null
}

variable "azure_mysql_password" {
  type        = string
  description = "Azure Database for MySQL password used by AWS DMS target endpoints."
  sensitive   = true
  default     = "data1234!"
  nullable    = false

  validation {
    condition     = length(trimspace(var.azure_mysql_password)) > 0
    error_message = "azure_mysql_password must not be blank. Set TF_VAR_azure_mysql_password before running terraform apply."
  }
}
