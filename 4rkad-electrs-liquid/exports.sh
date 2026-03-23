export APP_ELECTRS_LIQUID_NODE_PORT="60601"

# Elements RPC credentials (read from running container)
local elements_rpc_pass=$(docker inspect elements_node_1 --format '{{range .Config.Cmd}}{{.}} {{end}}' 2>/dev/null | grep -oP '(?<=-rpcpassword=)\S+' | head -1)
export APP_ELECTRS_LIQUID_ELEMENTS_RPC_PASS="${elements_rpc_pass:-}"
