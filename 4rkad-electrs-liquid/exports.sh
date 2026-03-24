export APP_ELECTRS_LIQUID_NODE_PORT="60601"

# App version (read from umbrel-app.yml so it stays in sync automatically)
local app_dir="$(dirname "${BASH_SOURCE[0]:-$0}")"
local app_version=$(grep '^version:' "${app_dir}/umbrel-app.yml" 2>/dev/null | sed 's/.*"\(.*\)".*/\1/')
export APP_ELECTRS_LIQUID_VERSION="${app_version:-0.0.0}"

# Tor onion address
local rpc_hidden_service_file="${EXPORTS_TOR_DATA_DIR}/app-${EXPORTS_APP_ID}/main/hostname"
export APP_ELECTRS_LIQUID_RPC_HIDDEN_SERVICE="$(cat "${rpc_hidden_service_file}" 2>/dev/null || echo "")"
