module "network" {
  source = "../../modules/network"

  namespace = local.namespace
}

module "platform" {
  source = "../../modules/platform"

  namespace      = local.namespace
  s3_bucket_name = local.bucket_name

  vpc_id = module.network.vpc["main"].id

  private_subnet_ids = [
    module.network.subnet["private-a-db"].id,
    module.network.subnet["private-c-db"].id
  ]
  node_security_group_id = module.workload.node_security_group_id
}

module "workload" {
  source = "../../modules/workload"

  namespace = local.namespace

  vpc_id     = module.network.vpc["main"].id
  account_id = local.account_id

  private_subnet_ids = [
    module.network.subnet["private-a"].id,
    module.network.subnet["private-c"].id
  ]
  public_subnet_id      = module.network.subnet["public-a"].id
  instance_type         = local.bastion.instance_type
  bastion_allowed_cidrs = local.bastion.allowed_cidrs
  all_admin_arns        = local.all_admin_arns
}