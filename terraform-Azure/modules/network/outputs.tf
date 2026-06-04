output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "location" {
  value = azurerm_resource_group.this.location
}

output "vnet" {
  value = {
    (local.vnet.name) = {
      id   = azurerm_virtual_network.this.id
      name = azurerm_virtual_network.this.name
    }
  }
}

output "subnet" {
  value = {
    (local.subnet_public[0].name) = {
      id         = azurerm_subnet.public_0.id
      cidr_block = azurerm_subnet.public_0.address_prefixes[0]
    }
    (local.subnet_public[1].name) = {
      id         = azurerm_subnet.public_1.id
      cidr_block = azurerm_subnet.public_1.address_prefixes[0]
    }
    (local.subnet_private[0].name) = {
      id         = azurerm_subnet.private_0.id
      cidr_block = azurerm_subnet.private_0.address_prefixes[0]
    }
    (local.subnet_private[1].name) = {
      id         = azurerm_subnet.private_1.id
      cidr_block = azurerm_subnet.private_1.address_prefixes[0]
    }
  }
}
