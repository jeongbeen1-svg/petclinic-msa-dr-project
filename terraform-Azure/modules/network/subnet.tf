resource "azurerm_subnet" "public_0" {
  name                 = "${local.namespace}-subnet-${local.subnet_public[0].name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_public[0].address_cidr]
}

resource "azurerm_subnet" "public_1" {
  name                 = "${local.namespace}-subnet-${local.subnet_public[1].name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_public[1].address_cidr]
}

resource "azurerm_subnet" "private_0" {
  name                 = "${local.namespace}-subnet-${local.subnet_private[0].name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_private[0].address_cidr]
}

resource "azurerm_subnet" "private_1" {
  name                 = "${local.namespace}-subnet-${local.subnet_private[1].name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_private[1].address_cidr]
}

resource "azurerm_subnet" "database" {
  name                 = "${local.namespace}-subnet-${local.subnet_database.name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_database.address_cidr]

  delegation {
    name = "mysql-flexible-server-delegation"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "dns_resolver" {
  name                 = "${local.namespace}-subnet-${local.subnet_dns_resolver.name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_dns_resolver.address_cidr]

  delegation {
    name = "dns-resolver-delegation"

    service_delegation {
      name = "Microsoft.Network/dnsResolvers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "dns_resolver_outbound" {
  name                 = "${local.namespace}-subnet-${local.subnet_dns_resolver_outbound.name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnet_dns_resolver_outbound.address_cidr]

  delegation {
    name = "dns-resolver-outbound-delegation"

    service_delegation {
      name = "Microsoft.Network/dnsResolvers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "gateway" {
  name                 = local.gateway_subnet.name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.gateway_subnet.address_cidr]
}

resource "azurerm_subnet_nat_gateway_association" "private_0" {
  subnet_id      = azurerm_subnet.private_0.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

resource "azurerm_subnet_nat_gateway_association" "private_1" {
  subnet_id      = azurerm_subnet.private_1.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}
