variable "namespace" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "node_security_group_id" {
  type = string
}

variable "bastion_security_group_id" {
  type = string
}

variable "azure_ip_cidr_block" {
  type = string
}

variable "private_subnets_dms" {
  type = list(string)
}

variable "target_username" {
  type = string
}

variable "target_password" {
  type      = string
  sensitive = true
}

variable "target_db_address" {
  type = string
}

variable "rds_mysql_password" {
  type        = string
  description = "Source RDS MySQL password used by AWS DMS."
  sensitive   = true
  default     = "data1234!"
}
