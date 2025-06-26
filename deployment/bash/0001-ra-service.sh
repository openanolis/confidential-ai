#! /bin/bash
mkdir -p kbs/data/attestation-service
mkdir -p kbs/config
mkdir -p kbs/data/reference-values
cat << EOF > kbs/config/as-config.json
{
    "work_dir": "/opt/confidential-containers/attestation-service",
    "policy_engine": "opa",
    "rvps_store_type": "LocalFs",
    "rvps_config": {
	"remote_addr":"http://rvps:50003"
    },
    "attestation_token_broker": "Simple",
    "attestation_token_config": {
        "duration_min": 5
    }
}
EOF

cat << EOF > kbs/config/sgx_default_qcnl.conf
# PCCS server address
PCCS_URL=https://sgx-dcap-server.cn-beijing.aliyuncs.com/sgx/certification/v4/
# To accept insecure HTTPS cert, set this option to FALSE
USE_SECURE_CERT=TRUE
EOF

cat << EOF > kbs/config/kbs-config.toml
sockets = ["0.0.0.0:8080"]
auth_public_key = "/opt/confidential-containers/kbs/user-keys/public.pub"
insecure_http = true

[attestation_token_config]
attestation_token_type = "CoCo"

[grpc_config]
as_addr = "http://as:50004"
EOF

cat << EOF > kbs/config/as.rego
package policy

default allow = true
EOF

cat << EOF > kbs/config/policy.rego
package policy

default allow = true
EOF

cat << EOF > kbs/config/kbs-config.toml
sockets = ["0.0.0.0:8080"]
auth_public_key = "/opt/confidential-containers/kbs/user-keys/public.pub"
insecure_http = true

[attestation_token_config]
attestation_token_type = "CoCo"

[grpc_config]
as_addr = "http://as:50004"
EOF

openssl genpkey -algorithm ed25519 > kbs/config/private.key
openssl pkey -in kbs/config/private.key -pubout -out kbs/config/public.pub

cat << EOF > docker-compose.yml
version: '3.2'
services:
  kbs:
    # build:
    #   context: .
    #   dockerfile: ./kbs/docker/Dockerfile.coco-as-grpc
    image: ghcr.io/confidential-containers/staged-images/kbs-grpc-as:3003ced913bf83fa11d3ef753bb621f9cd030ae8
    command: [
        "/usr/local/bin/kbs",
        "--config-file",
        "/etc/kbs-config.toml",
      ]
    restart: always # keep the server running
    environment:
      RUST_LOG: debug
    ports:
      - "8080:8080"
    volumes:
      - ./kbs/data/kbs-storage:/opt/confidential-containers/kbs/repository:rw
      - ./kbs/config/public.pub:/opt/confidential-containers/kbs/user-keys/public.pub
      - ./kbs/config/kbs-config.toml:/etc/kbs-config.toml
      - ./kbs/config/policy.rego:/opa/confidential-containers/kbs/policy.rego
    depends_on:
    - as

  as:
    # build:
    #   context: .
    #   dockerfile: ./attestation-service/Dockerfile.as-grpc
    image: ghcr.io/confidential-containers/staged-images/coco-as-grpc:0005ddb7381da2fc5e9f46597697c99252f46e4c
    ports:
    - "50004:50004"
    restart: always
    volumes:
    - ./kbs/data/attestation-service:/opt/confidential-containers/attestation-service:rw
    - ./kbs/config/as-config.json:/etc/as-config.json:rw
    - ./kbs/config/sgx_default_qcnl.conf:/etc/sgx_default_qcnl.conf:rw
    - ./kbs/config/as.rego:/opt/confidential-containers/attestation-service/opa/default.rego:rw
    command: [
      "grpc-as",
      "--socket",
      "0.0.0.0:50004",
      "--config-file",
      "/etc/as-config.json"
    ]
    depends_on:
    - rvps

  rvps:
    image: ghcr.io/confidential-containers/staged-images/rvps:3003ced913bf83fa11d3ef753bb621f9cd030ae8
    # build:
    #   context: .
    #   dockerfile: ./attestation-service/rvps/Dockerfile
    restart: always # keep the server running
    ports:
      - "50003:50003"
    volumes:
      - ./kbs/data/reference-values:/opt/confidential-containers/attestation-service/reference_values:rw
EOF

docker-compose up -d

mkdir -p kbs/data/kbs-storage/default/aliyun/
cat << EOF > kbs/data/kbs-storage/default/aliyun/ecs_ram_role
{
  "ecs_ram_role_name":"TDX-CAI-jiuzhong",
  "region_id":"cn-beijing"
}
EOF
