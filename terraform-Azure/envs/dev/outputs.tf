output "target_username" {
  value = module.platform.mysql_admin_username
}

output "target_password" {
  value = module.platform.mysql_admin_password
}

output "target_db_address" {
  value = module.platform.mysql_fqdn
}

output "azure_vnet_cidr" {
  value = module.network.vnet["main"].cidr
}

output "azure_vpn_gw_pip" {
  value = module.network.vpn_gateway.public_ip_address
}

output "azure_inbound_ips" {
  value = module.network.dns_private_resolver.inbound_ip_addresses
}

output "module" {
  value = {
    network  = module.network
    platform = module.platform
    workload = module.workload
  }

  # 보안상 있어야 apply됨
  sensitive = true
}
