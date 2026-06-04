module "network" {
  source = "../../modules/network"

  namespace = local.namespace
  location  = local.location
}

# module "platform" {
#   source = "../../modules/platform"
#
#   namespace           = local.namespace
#   location            = local.location
#   resource_group_name = module.network.resource_group_name
# }

module "workload" {
  source = "../../modules/workload"

  namespace           = local.namespace
  location            = local.location
  resource_group_name = module.network.resource_group_name
  vnet_id             = module.network.vnet["main"].id
  private_subnet_ids = [
    module.network.subnet["private-a"].id,
    module.network.subnet["private-b"].id
  ]
}
