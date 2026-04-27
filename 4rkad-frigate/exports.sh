export APP_FRIGATE_NODE_PORT="57001"

# Tor onion address
local rpc_hidden_service_file="${EXPORTS_TOR_DATA_DIR}/app-${EXPORTS_APP_ID}/main/hostname"
export APP_FRIGATE_RPC_HIDDEN_SERVICE="$(cat "${rpc_hidden_service_file}" 2>/dev/null || echo "")"
