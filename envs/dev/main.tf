module "network" {
  source = "../../modules/network"

  namespace = local.namespace
}

# module "platform" {
#   source = "../../modules/platform"

#   namespace = local.namespace

#   vpc_id = module.network.vpc["main"].id

#   lb_subnets           = [module.network.subnet["public-a"].id, module.network.subnet["public-b"].id]
#   lb_listener_port     = local.infra.lb.listener_port
#   lb_target_group_port = local.infra.lt.service_port
# }

module "workload" {
  source = "../../modules/workload"

  namespace = local.namespace

  vpc_id = module.network.vpc["main"].id
  private_subnet_ids = [
    module.network.subnet["private-a"].id,
    module.network.subnet["private-b"].id
  ]
}