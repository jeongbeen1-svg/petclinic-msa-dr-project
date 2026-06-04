module "network" {
  source = "../../modules/network"

  namespace = local.namespace
}

# module "platform" {
#   source = "../../modules/platform"

#   namespace = local.namespace

#   # vpc_id = module.network.vpc["main"].id

#   # lb_subnets           = [module.network.subnet["public-a"].id, module.network.subnet["public-b"].id]
#   # lb_listener_port     = local.infra.lb.listener_port
#   # lb_target_group_port = local.infra.lt.service_port
# }

module "workload" {
  source = "../../modules/workload"

  namespace = local.namespace

  vpc_id = module.network.vpc["main"].id
  private_subnet_ids = [
    module.network.subnet["private-a"].id,
    module.network.subnet["private-c"].id
  ]

  public_subnet_id      = module.network.subnet["public-a"].id
  instance_type         = local.bastion.instance_type
  bastion_allowed_cidrs = local.bastion.allowed_cidrs
  all_admin_arns        = local.all_admin_arns
}