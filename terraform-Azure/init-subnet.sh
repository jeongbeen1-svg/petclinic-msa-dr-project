#!/bin/bash
SUB="cc7b3135-0c37-4515-8292-aa7b87e60ad8"
RG="tf-core-jaebok1205-test-dev-rg"
VNET="tf-core-jaebok1205-test-dev-vnet-main"
BASE="/subscriptions/${SUB}/resourceGroups/${RG}/providers/Microsoft.Network/virtualNetworks/${VNET}/subnets"

echo "=== Subnet import 시작 ==="

terraform import module.network.azurerm_subnet.public_0  "${BASE}/tf-core-jaebok1205-test-dev-subnet-public-a"
terraform import module.network.azurerm_subnet.public_1  "${BASE}/tf-core-jaebok1205-test-dev-subnet-public-b"
terraform import module.network.azurerm_subnet.private_0 "${BASE}/tf-core-jaebok1205-test-dev-subnet-private-a"
terraform import module.network.azurerm_subnet.private_1 "${BASE}/tf-core-jaebok1205-test-dev-subnet-private-b"

echo "=== 완료 ==="