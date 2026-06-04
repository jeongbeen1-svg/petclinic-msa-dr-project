resource "azurerm_storage_account" "this" {
  name                     = substr(replace(lower("${local.namespace}storage"), "-", ""), 0, 24)
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.common_tags
}

resource "azurerm_storage_container" "this" {
  name                  = "app"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
