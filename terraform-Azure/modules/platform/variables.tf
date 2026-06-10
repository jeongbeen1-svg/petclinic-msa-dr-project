variable "namespace" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "dms_ip" {
  type = string
}

variable "my_ip" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}
