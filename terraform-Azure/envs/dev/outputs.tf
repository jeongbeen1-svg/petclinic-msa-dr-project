output "target_username" {
  value = data.azurerm_key_vault_secret.db_username.value
}

output "target_password" {
  value = data.azurerm_key_vault_secret.db_password.value
}

output "target_db_address" {
  value = module.platform.azurerm_mysql_flexible_server.mysql.fqdn
}

output "azure_vnet_cidr" {
  value = module.network.vnet["main"].cidr
}

output "azure_vpn_gw_pip" {
  value = module.network.azurerm_public_ip.vpn_gateway.ip_address
}

output "azure_inbound_ips" {
  value = module.network.azurerm_private_dns_resolver_inbound_endpoint.this.ip_configurations[0].private_ip_address
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
