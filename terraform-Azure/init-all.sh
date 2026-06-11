#!/bin/bash
SUB="cc7b3135-0c37-4515-8292-aa7b87e60ad8"
RG="tf-core-jaebok1205-test-dev-rg"
BASE="/subscriptions/${SUB}/resourceGroups/${RG}/providers"
VNET="tf-core-jaebok1205-test-dev-vnet-main"

echo "=== 전체 리소스 import 시작 ==="

# Subnet
terraform import module.network.azurerm_subnet.public_0  "${BASE}/Microsoft.Network/virtualNetworks/${VNET}/subnets/tf-core-jaebok1205-test-dev-subnet-public-a"
terraform import module.network.azurerm_subnet.public_1  "${BASE}/Microsoft.Network/virtualNetworks/${VNET}/subnets/tf-core-jaebok1205-test-dev-subnet-public-b"
terraform import module.network.azurerm_subnet.private_0 "${BASE}/Microsoft.Network/virtualNetworks/${VNET}/subnets/tf-core-jaebok1205-test-dev-subnet-private-a"
terraform import module.network.azurerm_subnet.private_1 "${BASE}/Microsoft.Network/virtualNetworks/${VNET}/subnets/tf-core-jaebok1205-test-dev-subnet-private-b"

# AKS (resource name: main)
terraform import module.workload.azurerm_kubernetes_cluster.main \
  "${BASE}/Microsoft.ContainerService/managedClusters/tf-core-jaebok1205-test-dev-aks"

# Storage Account (platform 모듈)
terraform import module.platform.azurerm_storage_account.this \
  "${BASE}/Microsoft.Storage/storageAccounts/tfcorejaebok1205testdevs"

# Private DNS Zone (platform 모듈)
terraform import module.platform.azurerm_private_dns_zone.mysql \
  "${BASE}/Microsoft.Network/privateDnsZones/privatelink.mysql.database.azure.com"

# Private DNS Zone VNet Link (platform 모듈)
terraform import module.platform.azurerm_private_dns_zone_virtual_network_link.mysql \
  "${BASE}/Microsoft.Network/privateDnsZones/privatelink.mysql.database.azure.com/virtualNetworkLinks/tf-core-jaebok1205-test-dev-mysql-dns-link"

echo "=== import 완료 ==="