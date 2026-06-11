locals {
  namespace           = var.namespace
  location            = var.location
  resource_group_name = var.resource_group_name

  cluster_name = "${local.namespace}-aks"
  common_tags = {
    Environment = "dev"
    Project     = "Project3-MSA"
    ManagedBy   = "Terraform"
  }

  vnet_id            = var.vnet_id
  private_subnet_ids = var.private_subnet_ids
}
