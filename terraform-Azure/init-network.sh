#!/bin/bash
SUB="cc7b3135-0c37-4515-8292-aa7b87e60ad8"
RG="tf-core-jaebok1205-test-dev-rg"
PREFIX="/subscriptions/${SUB}/resourceGroups/${RG}/providers"

echo "=== Network 리소스 import 시작 ==="

# VNet
terraform import \
  module.network.azurerm_virtual_network.this \
  "${PREFIX}/Microsoft.Network/virtualNetworks/tf-core-jaebok1205-test-dev-vnet-main"

# Public IP
terraform import \
  module.network.azurerm_public_ip.nat \
  "${PREFIX}/Microsoft.Network/publicIPAddresses/tf-core-jaebok1205-test-dev-pip-natgw-main"

# NAT Gateway
terraform import \
  module.network.azurerm_nat_gateway.this \
  "${PREFIX}/Microsoft.Network/natGateways/tf-core-jaebok1205-test-dev-natgw-main"

echo "=== 완료 ==="