export APP_ELECTRS_LIQUID_NODE_PORT="60601"

# App version — update here when bumping version in umbrel-app.yml
export APP_ELECTRS_LIQUID_VERSION="0.7.0"

# Tor onion address
local rpc_hidden_service_file="${EXPORTS_TOR_DATA_DIR}/app-${EXPORTS_APP_ID}/main/hostname"
export APP_ELECTRS_LIQUID_RPC_HIDDEN_SERVICE="$(cat "${rpc_hidden_service_file}" 2>/dev/null || echo "")"
