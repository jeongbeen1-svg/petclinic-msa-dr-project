output "module" {
  value = {
    network  = module.network
    platform = module.platform
    workload = module.workload
  }

  # 보안상 있어야 apply됨
  sensitive = true
}
