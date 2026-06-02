locals {
  namespace = var.namespace

  cluster_name = "${local.namespace}-eks"
  common_tags = {
    Environment = "dev"
    Project     = "Project3-MSA"
    ManagedBy   = "Terraform"
  }
}