locals {
  namespace = var.namespace

  cluster_name = "${local.namespace}-eks"

  common_tags = {
    Environment = "dev"
    Project     = "Project3-MSA"
    ManagedBy   = "Terraform"
  }

  vpc_id                = var.vpc_id
  public_subnet_id      = var.public_subnet_id
  instance_type         = var.instance_type
  bastion_allowed_cidrs = var.bastion_allowed_cidrs
  all_admin_arns        = var.all_admin_arns
}