output "module" {
  value = {
    network  = module.network
    platform = module.platform
    workload = module.workload
  }

  sensitive = true
}
