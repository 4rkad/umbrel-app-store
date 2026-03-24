export APP_ELECTRS_LIQUID_NODE_PORT="60601"

# App version — update here when bumping version in umbrel-app.yml
export APP_ELECTRS_LIQUID_VERSION="0.7.2"

# Elements RPC password
# Try docker inspect first (works when Elements is running)
local elements_container=$(docker ps --filter name=elements --format '{{.Names}}' 2>/dev/null | grep -E 'elements.node' | head -1)
local elements_rpc_pass=""
if [ -n "$elements_container" ]; then
    elements_rpc_pass=$(docker inspect "$elements_container" --format '{{range .Config.Cmd}}{{.}} {{end}}' 2>/dev/null | grep -oP '(?<=-rpcpassword=)\S+' | head -1)
fi

# Persist password for reboots (pattern from Bitcoin app .env)
local pass_file="${EXPORTS_APP_DIR}/data/electrs/.elements_rpc_pass"
if [ -n "$elements_rpc_pass" ]; then
    echo "$elements_rpc_pass" > "$pass_file" 2>/dev/null || true
elif [ -f "$pass_file" ]; then
    elements_rpc_pass=$(cat "$pass_file" 2>/dev/null)
fi
export APP_ELECTRS_LIQUID_ELEMENTS_RPC_PASS="${elements_rpc_pass:-}"

# Tor onion address
local rpc_hidden_service_file="${EXPORTS_TOR_DATA_DIR}/app-${EXPORTS_APP_ID}/main/hostname"
export APP_ELECTRS_LIQUID_RPC_HIDDEN_SERVICE="$(cat "${rpc_hidden_service_file}" 2>/dev/null || echo "")"
