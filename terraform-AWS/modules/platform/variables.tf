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

variable "azure_conn_string" {
  type        = string
  description = "Azure Storage 연결 문자열"
  sensitive   = true
}