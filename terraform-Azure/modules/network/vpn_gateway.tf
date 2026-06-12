resource "azurerm_public_ip" "vpn_gateway" {
  name                = "${local.namespace}-pip-vpngw-${local.vpn_gateway.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]

  tags = local.common_tags
}

resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "${local.namespace}-vpngw-${local.vpn_gateway.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1AZ"

  active_active = false
  bgp_enabled   = false

  ip_configuration {
    name                          = "default"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  tags = local.common_tags
}

resource "azurerm_local_network_gateway" "aws" {
  for_each = var.aws_vpn_tunnels

  name                = each.value.local_network_gateway_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  gateway_address     = each.value.gateway_ip_address
  address_space       = [var.aws_vpc_cidr]
}

resource "azurerm_virtual_network_gateway_connection" "aws" {
  for_each = var.aws_vpn_tunnels

  name                       = each.value.connection_name
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws[each.key].id
  shared_key                 = coalesce(each.value.shared_key, "managed-outside-terraform")

  connection_protocol = "IKEv2"
  dpd_timeout_seconds = 45
  bgp_enabled         = false
  routing_weight      = 0
}
