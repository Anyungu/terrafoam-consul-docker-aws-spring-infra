#!/bin/sh

# Set variables rebuild
CURRENT_SERVER_ADDRESS=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

check_environment_variables() {
    if [ -z "$CONSUL_HTTP_TOKEN" ]; then
        echo "Go and set your CONSUL_HTTP_TOKEN."
        exit 1
    fi

    if [ -z "$CONSUL_GOSSIP_ENCRYPT" ]; then
        echo "Go and set your CONSUL_GOSSIP_ENCRYPT."
        exit 1
    fi

    echo "SETTING CONSUL_HTTP_ADDR and CONSUL_GRPC_ADDR will default to EC2 Host IP."
    export CONSUL_HTTP_SSL=true
    export CONSUL_HTTP_ADDR=https://$CURRENT_SERVER_ADDRESS:8501
    export CONSUL_GRPC_ADDR=$CURRENT_SERVER_ADDRESS:8502

}

# Set variables rebuild
OUR_SERVER_ADDRESS=$(ip addr show eth0 | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")

# Collect sample json file reboot
# retry users
SAMPLE_FILE=$(cat ./opt/consul/configs/consul.json)

# Read in template one line at the time, and replace variables (more natural (and efficient) way, thanks to Jonathan Leffler).
JSON_STRING=$(jq -n --arg snadress "$OUR_SERVER_ADDRESS" "$SAMPLE_FILE")

echo $JSON_STRING >>/etc/consul.d/consul.json

# Initialize the consul agent
# envoy -c /etc/envoy/envoy.yaml
consul agent -config-file /etc/consul.d/consul.json

#!/bin/sh
# SERVICE="activities"

OUR_SERVER_ADDRESS=$(ip addr show eth0 | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")

# Collect sample json file remove auto
# SAMPLE_FILE=$(cat ./opt/consul/configs/config.mapper.json)

# Read in template one line at the time, and replace variables (more natural (and efficient) way, thanks to Jonathan Leffler).
# JSON_STRING=$(jq -n --arg service "$SERVICE" "$SAMPLE_FILE")

# echo $JSON_STRING >> /opt/consul/configs/service_"$SERVICE"_consul.json

consul config write -http-addr="$OUR_SERVER_ADDRESS:8500" /opt/consul/configs/protocol.hcl

consul connect envoy -http-addr="$OUR_SERVER_ADDRESS:8500" -grpc-addr="$OUR_SERVER_ADDRESS:8502" -token=4ef9ecc4-2c06-0dae-4183-b0282dcdb361 -sidecar-for notifications-1
