locals {
  namespace = var.namespace
  location  = var.location
  resource_group_name = var.resource_group_name

  common_tags = {
    Environment = "dev"
    Project     = "Project3-MSA"
    ManagedBy   = "Terraform"
  }

  dms_ip = var.dms_ip
  my_ip  = var.my_ip
}
