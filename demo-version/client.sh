#!/bin/bash

docker rm -f envoy_librats_container_client_qwen_ok > /dev/null 2>&1

docker run -d --name envoy_librats_container_client_qwen_ok \
    -v client-ws.yaml:/home/envoy-demo-tls-client-ws.yaml \
    -v kbs/config/sgx_default_qcnl.conf:/etc/sgx_default_qcnl.conf \
    -p 11000:11000 \
    xynnn007/envoy:light \
    envoy-static \
    -c /home/envoy-demo-tls-client-ws.yaml \
    -l off --component-log-level upstream:error,connection:debug \
    > /dev/null 2>&1

echo TNG proxy listens port 11000