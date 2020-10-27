# notifications consul agent rebuild rebuild rebuild
ARG ENVOY_VERSION=1.14-latest

ARG CONSUL_VERSION=1.8.0

FROM envoyproxy/envoy-alpine:v${ENVOY_VERSION}

RUN apk update && apk add -u bash curl jq --no-cache && \
    wget https://releases.hashicorp.com/consul/"${CONSUL_VERSION}"/consul_"${CONSUL_VERSION}"_linux_amd64.zip \
    -O /tmp/consul.zip && \
    unzip /tmp/consul.zip -d /tmp && \
    mv /tmp/consul /usr/local/bin/consul && \
    rm -f /tmp/consul.zip && \
    mkdir -p /opt/consul  && \
    mkdir -p /etc/consul.d 

ADD configs /opt/consul/configs

ADD scripts /opt/consul/scripts

RUN chmod +x /opt/consul/scripts/entrypoint.sh


ENTRYPOINT ["/entrypoint.sh"]