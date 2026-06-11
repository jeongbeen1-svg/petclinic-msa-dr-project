#!/usr/bin/env bash
set -euo pipefail

TF_BIN="${TF_BIN:-terraform}"
ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/envs/dev" && pwd)"
SUBSCRIPTION_ID="cc7b3135-0c37-4515-8292-aa7b87e60ad8"
RESOURCE_GROUP="tf-core-jaebok1205-test-dev-rg"
VNET_NAME="tf-core-jaebok1205-test-dev-vnet-main"
NAT_GATEWAY_NAME="tf-core-jaebok1205-test-dev-natgw-main"
NAT_PUBLIC_IP_NAME="tf-core-jaebok1205-test-dev-pip-natgw-main"

cd "$ENV_DIR"

DB_PASS="$("$TF_BIN" state pull \
  | jq -r '.resources[]
    | select(.module == "module.platform"
      and .type == "azurerm_mysql_flexible_server"
      and .name == "mysql")
    | .instances[0].attributes.administrator_password')"

if [[ -z "$DB_PASS" || "$DB_PASS" == "null" ]]; then
  echo "Existing MySQL administrator password was not found in Terraform state." >&2
  exit 1
fi

import_if_missing() {
  local address="$1"
  local id="$2"

  if "$TF_BIN" state show "$address" >/dev/null 2>&1; then
    echo "Already imported: $address"
    return
  fi

  TF_VAR_db_password="$DB_PASS" "$TF_BIN" import -input=false "$address" "$id"
}

SUBNET_BASE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${VNET_NAME}/subnets"
NAT_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/natGateways/${NAT_GATEWAY_NAME}"
PIP_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/publicIPAddresses/${NAT_PUBLIC_IP_NAME}"

import_if_missing \
  'module.network.azurerm_subnet_nat_gateway_association.private_0' \
  "${SUBNET_BASE}/tf-core-jaebok1205-test-dev-subnet-private-a"

import_if_missing \
  'module.network.azurerm_subnet_nat_gateway_association.private_1' \
  "${SUBNET_BASE}/tf-core-jaebok1205-test-dev-subnet-private-b"

import_if_missing \
  'module.network.azurerm_nat_gateway_public_ip_association.this' \
  "${NAT_ID}|${PIP_ID}"
