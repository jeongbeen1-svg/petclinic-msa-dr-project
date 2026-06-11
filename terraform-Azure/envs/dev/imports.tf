import {
  to = module.network.azurerm_local_network_gateway.aws["tunnel-1"]
  id = "/subscriptions/cc7b3135-0c37-4515-8292-aa7b87e60ad8/resourceGroups/tf-core-jaebok1205-test-dev-rg/providers/Microsoft.Network/localNetworkGateways/local-networ-gw-tunnel-1"
}

import {
  to = module.network.azurerm_local_network_gateway.aws["tunnel-2"]
  id = "/subscriptions/cc7b3135-0c37-4515-8292-aa7b87e60ad8/resourceGroups/tf-core-jaebok1205-test-dev-rg/providers/Microsoft.Network/localNetworkGateways/local-networ-gw-tunnel-2"
}

import {
  to = module.network.azurerm_virtual_network_gateway_connection.aws["tunnel-1"]
  id = "/subscriptions/cc7b3135-0c37-4515-8292-aa7b87e60ad8/resourceGroups/tf-core-jaebok1205-test-dev-rg/providers/Microsoft.Network/connections/vpn-conn"
}

import {
  to = module.network.azurerm_virtual_network_gateway_connection.aws["tunnel-2"]
  id = "/subscriptions/cc7b3135-0c37-4515-8292-aa7b87e60ad8/resourceGroups/tf-core-jaebok1205-test-dev-rg/providers/Microsoft.Network/connections/vpn-conn2"
}

import {
  to = module.network.azurerm_private_dns_resolver_outbound_endpoint.this
  id = "/subscriptions/cc7b3135-0c37-4515-8292-aa7b87e60ad8/resourceGroups/tf-core-jaebok1205-test-dev-rg/providers/Microsoft.Network/dnsResolvers/tf-core-jaebok1205-test-dev-pdnsr-main/outboundEndpoints/tf-core-jaebok1205-test-dev-pdnsr-outbound"
}
