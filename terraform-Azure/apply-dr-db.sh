#!/usr/bin/env bash
set -euo pipefail

TF_BIN="${TF_BIN:-terraform}"
ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/envs/dev" && pwd)"

check_azure_auth() {
  if command -v az >/dev/null 2>&1; then
    return 0
  fi

  if [[ -n "${ARM_SUBSCRIPTION_ID:-}" && -n "${ARM_TENANT_ID:-}" ]]; then
    if [[ -n "${ARM_CLIENT_ID:-}" && -n "${ARM_CLIENT_SECRET:-}" ]] || [[ -n "${ARM_USE_MSI:-}" ]]; then
      return 0
    fi
  fi

  cat >&2 <<'EOF'
Azure authentication is required for Terraform Azure provider/backend.
Install Azure CLI and run 'az login', or configure service principal auth:
  export ARM_SUBSCRIPTION_ID=...
  export ARM_TENANT_ID=...
  export ARM_CLIENT_ID=...
  export ARM_CLIENT_SECRET=...
Or, for managed identity auth, set ARM_USE_MSI=true.
EOF
  exit 1
}

check_azure_auth

cd "$ENV_DIR"

"$TF_BIN" init -input=false
"$TF_BIN" validate

DB_PASS="$("$TF_BIN" state pull \
  | jq -r '.resources[]
    | select(.module == "module.platform"
      and .type == "azurerm_mysql_flexible_server"
      and .name == "mysql")
    | .instances[0].attributes.administrator_password')"

if [[ -z "$DB_PASS" || "$DB_PASS" == "null" ]]; then
  echo "Existing MySQL administrator password was not found in Terraform state." >&2
  echo "Set TF_VAR_db_password and rerun this script." >&2
  exit 1
fi

TF_VAR_db_password="$DB_PASS" "$TF_BIN" plan -out=tfplan -input=false

if "$TF_BIN" show -json tfplan \
  | jq -e '.resource_changes[]
    | select(.change.actions | index("delete"))' >/dev/null; then
  echo "Plan contains a delete action. Refusing to apply automatically." >&2
  "$TF_BIN" show tfplan
  exit 1
fi

# TF_VAR_db_password="$DB_PASS" "$TF_BIN" apply -input=false tfplan
TF_VAR_db_password="$DB_PASS" "$TF_BIN" apply -input=false tfplan