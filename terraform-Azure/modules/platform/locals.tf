locals {
  namespace           = var.namespace
  location            = var.location
  resource_group_name = var.resource_group_name

  mysql = {
    server_name           = substr(replace(lower("${local.namespace}-mysql"), "-", ""), 0, 63)
    database_name         = "petclinic"
    version               = "8.0.21"
    sku_name              = "B_Standard_B1ms"
    storage_size_gb       = 20
    backup_retention_days = 7
  }

  common_tags = {
    Environment = "dev"
    Project     = "Project3-MSA"
    ManagedBy   = "Terraform"
  }

  dms_ip             = var.dms_ip
  my_ip              = var.my_ip
  private_subnet_ids = var.private_subnet_ids
}
