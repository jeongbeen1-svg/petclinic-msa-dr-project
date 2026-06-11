locals {
  namespace = var.namespace

  cluster_name = "${local.namespace}-aks"
  bastion = {
    name           = "${local.namespace}-bastion"
    admin_username = "azureuser"
    vm_size        = "Standard_B1s"
  }

  common_tags = {
    Environment = "dev"
    Project     = "Project3-MSA"
    ManagedBy   = "Terraform"
  }
}
