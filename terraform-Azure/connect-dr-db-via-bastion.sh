#!/usr/bin/env bash
set -euo pipefail

TF_BIN="${TF_BIN:-terraform}"
ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/envs/dev" && pwd)"
BASTION_IP="${BASTION_IP:-20.249.102.34}"
BASTION_USER="${BASTION_USER:-azureuser}"
BASTION_KEY="${BASTION_KEY:-${ENV_DIR}/bastion_key.pem}"
DB_HOST="${DB_HOST:-tfcorejaebok1205testdevmysql.mysql.database.azure.com}"
DB_USER="${DB_USER:-petclinicadmin}"
DB_NAME="${DB_NAME:-petclinic_dr_test}"

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

ssh -i "$BASTION_KEY" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  "${BASTION_USER}@${BASTION_IP}" \
  "MYSQL_PWD='${DB_PASS}' mysql -h '${DB_HOST}' -P 3306 -u '${DB_USER}' -D '${DB_NAME}' --ssl-mode=REQUIRED"
