locals {
  namespace = var.namespace

  vpc_id                 = var.vpc_id
  private_subnet_ids     = var.private_subnet_ids
  node_security_group_id = var.node_security_group_id
  bastion_security_group_id = var.bastion_security_group_id
}