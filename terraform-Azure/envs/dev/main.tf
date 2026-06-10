module "network" {
  source = "../../modules/network"

  namespace = local.namespace
  location  = local.location
}

module "platform" {
  source = "../../modules/platform"

  namespace           = local.namespace
  location            = local.location
  resource_group_name = module.network.resource_group_name

  dms_ip = local.dms_ip
  my_ip  = local.my_ip

  private_subnet_ids = [
    module.network.subnet["private-db-a"].id,
    module.network.subnet["private-db-c"].id
  ]
}

module "workload" {
  source = "../../modules/workload"

  namespace           = local.namespace
  location            = local.location
  resource_group_name = module.network.resource_group_name
  vnet_id             = module.network.vnet["main"].id
  private_subnet_ids = [
    module.network.subnet["private-a"].id,
    module.network.subnet["private-c"].id
  ]
}
