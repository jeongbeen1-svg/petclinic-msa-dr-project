#!/usr/bin/env bash
set -euo pipefail

cd /home/jaebok1205/test/terraform-Azure/envs/dev

terraform import -var='db_password=Dummy123!ForDestroy' \
  'module.network.azurerm_virtual_network_gateway_connection.aws["tunnel-1"]' \
  '/subscriptions/cc7b3135-0c37-4515-8292-aa7b87e60ad8/resourceGroups/tf-core-jaebok1205-test-dev-rg/providers/Microsoft.Network/connections/vpn-conn'

terraform import -var='db_password=Dummy123!ForDestroy' \
  'module.network.azurerm_virtual_network_gateway_connection.aws["tunnel-2"]' \
  '/subscriptions/cc7b3135-0c37-4515-8292-aa7b87e60ad8/resourceGroups/tf-core-jaebok1205-test-dev-rg/providers/Microsoft.Network/connections/vpn-conn2'

terraform import -var='db_password=Dummy123!ForDestroy' \
  'module.network.azurerm_local_network_gateway.aws["tunnel-1"]' \
  '/subscriptions/cc7b3135-0c37-4515-8292-aa7b87e60ad8/resourceGroups/tf-core-jaebok1205-test-dev-rg/providers/Microsoft.Network/localNetworkGateways/local-networ-gw-tunnel-1'

terraform import -var='db_password=Dummy123!ForDestroy' \
  'module.network.azurerm_local_network_gateway.aws["tunnel-2"]' \
  '/subscriptions/cc7b3135-0c37-4515-8292-aa7b87e60ad8/resourceGroups/tf-core-jaebok1205-test-dev-rg/providers/Microsoft.Network/localNetworkGateways/local-networ-gw-tunnel-2'
