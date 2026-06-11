resource "azurerm_private_dns_zone" "mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "${local.namespace}-mysql-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = local.mysql.server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.db_username
  administrator_password = var.db_password
  backup_retention_days  = local.mysql.backup_retention_days
  delegated_subnet_id    = var.db_subnet_id
  private_dns_zone_id    = azurerm_private_dns_zone.mysql.id
  public_network_access  = "Disabled"
  sku_name               = local.mysql.sku_name
  version                = local.mysql.version

  storage {
    size_gb = local.mysql.storage_size_gb
  }

  tags = merge(local.common_tags, {
    Name = "${local.namespace}-petclinic-mysql"
  })

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mysql
  ]
}

resource "azurerm_mysql_flexible_database" "petclinic" {
  name                = local.mysql.database_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}
