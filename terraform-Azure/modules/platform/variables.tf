variable "namespace" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "db_subnet_id" {
  type = string
}

variable "db_username" {
  type        = string
  description = "Azure MySQL administrator username"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Azure MySQL administrator password"
}

variable "dms_ip" {
  type        = string
  description = "AWS DMS replication instance public IP allowed to access Azure MySQL."
  default     = ""
}

variable "my_ip" {
  type        = string
  description = "Operator public IP allowed to access Azure MySQL during tests."
  default     = ""
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs kept for DMS-related compatibility."
  default     = []
}
