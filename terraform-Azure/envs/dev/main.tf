module "network" {
  source = "../../modules/network"

  namespace = local.namespace
  location  = local.location

  aws_vpc_cidr = local.aws_vpc_cidr
}

module "platform" {
  source = "../../modules/platform"

  namespace           = local.namespace
  location            = local.location
  resource_group_name = module.network.resource_group_name
  vnet_id             = module.network.vnet["main"].id
  db_subnet_id        = module.network.subnet["db"].id
  db_username         = var.db_username
  db_password         = var.db_password
}

module "workload" {
  source = "../../modules/workload"

  depends_on = [module.platform]

  namespace           = local.namespace
  location            = local.location
  resource_group_name = module.network.resource_group_name
  vnet_id             = module.network.vnet["main"].id
  public_subnet_id    = module.network.subnet["public-a"].id
  private_subnet_ids = [
    module.network.subnet["private-a"].id,
    module.network.subnet["private-c"].id
  ]
  bastion_allowed_cidrs = var.bastion_allowed_cidrs
}
