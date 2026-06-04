output "module" {
  value = {
    network  = module.network
    workload = module.workload
  }

  sensitive = true
}
