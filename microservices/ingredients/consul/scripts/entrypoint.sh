#!/bin/sh

# Set variables rebuild
CURRENT_SERVER_ADDRESS=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

check_environment_variables_for_stability() {
    if [ -z "$CONSUL_HTTP_TOKEN" ]; then
        echo "Go and set your CONSUL_HTTP_TOKEN."
        exit 1
    fi

    if [ -z "$CONSUL_GOSSIP_ENCRYPT" ]; then
        echo "Go and set your CONSUL_GOSSIP_ENCRYPT."
        exit 1
    fi

    if [ -z "$CONSUL_CA_PEM" ]; then
        echo "set CONSUL_CA_PEM to base64 encoded contents of server ca.pem file."
        exit 1
    fi

    if [ -z "$CONSUL_DATACENTER" ]; then
        echo "CONSUL_DATACENTER will default to dc1."
        CONSUL_DATACENTER="dc1"
    fi

    if [ -z "$CONSUL_SERVER_ADDRESS" ]; then
        echo "set a remote server address"
        CONSUL_DATACENTER="dc1"
    fi

    if [ -z "$SERVICE_NAME" ]; then
        echo "set SERVICE_NAME to service name."
        exit 1
    fi

    if [ -z "$SERVICE_PORT" ]; then
        echo "set SERVICE_PORT to service port."
        exit 1
    fi

    if [ -z "$SERVICE_HEALTH_CHECK_PATH" ]; then
        echo "SERVICE_HEALTH_CHECK_PATH will default to /."
        SERVICE_HEALTH_CHECK_PATH=/
    fi

    if [ -z "$SERVICE_HEALTH_CHECK_INTERVAL" ]; then
        echo "SERVICE_HEALTH_CHECK_INTERVAL will default to 1s."
        SERVICE_HEALTH_CHECK_INTERVAL="5s"
    fi

    echo "SETTING CONSUL_HTTP_ADDR and CONSUL_GRPC_ADDR which will default to EC2 Host IP."
    export CONSUL_HTTP_SSL=true
    export CONSUL_HTTP_ADDR="https://${CURRENT_SERVER_ADDRESS}:8501"
    export CONSUL_GRPC_ADDR="${CURRENT_SERVER_ADDRESS}:8502"

}

set_consul_client_agent_full_configuration() {

    echo "Decoding base64 ca.pem to /consul/ca.pem."
    echo $CONSUL_CA_PEM | base64 -d >/opt/consul/configs/consul-agent-ca.pem

    CLIENT_CONFIG_FILE="/opt/consul/configs/client.json"

    SERVICE_CHECK_ADDRESS="http://${CURRENT_SERVER_ADDRESS}:${SERVICE_PORT}${SERVICE_HEALTH_CHECK_PATH}",

    jq '.addresses.http="'$CURRENT_SERVER_ADDRESS'" |
        .addresses.grpc="'$CURRENT_SERVER_ADDRESS'" |
        .datacenter = "'${CONSUL_DATACENTER}'" | 
        .retry_join = ["'${CONSUL_SERVER_ADDRESS}'"] |
        .encrypt = "'${CONSUL_GOSSIP_ENCRYPT}'" | 
        .acl.tokens.default = "'${CONSUL_HTTP_TOKEN}'" | 
        .service.check[].http = "'${SERVICE_CHECK_ADDRESS}'" |
        .service.check[].id = "'${SERVICE_NAME}-check'" |
        .service.check[].interval = "'${SERVICE_HEALTH_CHECK_INTERVAL}'" |
        .service.check[].timeout = "3s" |
        .service.id = "'${SERVICE_NAME}-1'" |
        .service.name = "'${SERVICE_NAME}'" |
        .service.port = "'${SERVICE_PORT}'"' ./opt/consul/configs/agent_config.json >${CLIENT_CONFIG_FILE}

    trap "consul leave" SIGINT SIGTERM EXIT

    consul agent -config-file /opt/consul/configs/client.json &

    # consul config write /opt/consul/configs/protocol.hcl &

    consul connect envoy -sidecar-for ${SERVICE_NAME}-1 &

    # Block using tail so the trap will fire
    tail -f /dev/null &
    PID=$!
    wait $PID
}

check_environment_variables_for_stability

set_consul_client_agent_full_configuration
