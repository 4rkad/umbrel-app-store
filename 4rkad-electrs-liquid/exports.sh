export APP_ELECTRS_LIQUID_NODE_PORT="60601"

# Elements RPC credentials (read from running container)
# Try both Docker Compose v1 (underscore) and v2 (hyphen) naming
local elements_container=$(docker ps --filter name=elements --format '{{.Names}}' 2>/dev/null | grep -E 'elements.node' | head -1)
local elements_rpc_pass=""
if [ -n "$elements_container" ]; then
    elements_rpc_pass=$(docker inspect "$elements_container" --format '{{range .Config.Cmd}}{{.}} {{end}}' 2>/dev/null | grep -oP '(?<=-rpcpassword=)\S+' | head -1)
fi
export APP_ELECTRS_LIQUID_ELEMENTS_RPC_PASS="${elements_rpc_pass:-}"
