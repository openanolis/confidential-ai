#!/bin/bash

if [ "$#" -ne 6 ]; then
  cat <<-EOF
Usage:
  - ./ra-deploy-model.sh
    <ak-id-vault-id>
    <ak-secret-vault-id>
    <gocryptfs-password-vault-id>
    <oss-bucket-id>
    <oss-bucket-path>
    <kbs-addr>
    

Example:
  ./ra-deploy-qwen.sh
    cai-oss-AccessKeyID
    cai-oss-AccessKeySecret
    gocryptfs-password
    jingyao-tdx-cai
    /qwen
    http://127.0.0.1:8080
EOF

  exit -1
fi

set -e

ak_id_vault_id=$1
ak_secret_vault_id=$2
gocrypt_fs_password=$3
bucket=$4
bucket_path=$5
as_addr=$6

if [ ! -d "guest-components" ]; then
  echo Build CDH/AA and install CDH client...
  git clone https://github.com/confidential-containers/guest-components.git
  pushd guest-components
  git checkout 023faf776546139aeb7175be816e57126866a5ac
  make TEE_PLATFORM=tdx LIBC=gnu
  pushd confidential-data-hub/hub 
  cargo build --bin cdh-tool --features bin
  sudo install -D -m0755 ../../target/x86_64-unknown-linux-gnu/release/cdh-tool /usr/local/bin/cdh-tool
  popd
  popd
fi

echo launch AA and CDH ...

cat << EOF > cdh-config.toml
[kbc]
name = "cc_kbc"
url = "${as_addr}"

[[credentials]]
resource_uri = "kbs:///default/aliyun/ecs_ram_role"
path = "/run/confidential-containers/cdh/kms-credential/aliyun/ecsRamRole.json"
EOF

if [ -d "aa.pid" ]; then
  kill $(cat aa.pid) > /dev/null 2>&1
fi

AA_KBC_PARAMS=cc_kbc::${as_addr} \
  RUST_LOG=debug \
  ./guest-components/target/x86_64-unknown-linux-gnu/release/attestation-agent > aa.log 2>&1 &
echo $! > aa.pid

if [ -d "cdh.pid" ]; then
  kill $(cat cdh.pid) > /dev/null 2>&1
fi

AA_KBC_PARAMS=cc_kbc::${as_addr} \
  RUST_LOG=debug \
  ./guest-components/target/x86_64-unknown-linux-gnu/release/confidential-data-hub \
  -c cdh-config.toml \
  > cdh.log 2>&1 &
echo $! > cdh.pid

sleep 5
cat << EOF > sealed-secret-akid.json
{
  "version": "0.1.0",
  "type": "vault",
  "name": "${ak_id_vault_id}",
  "provider": "aliyun",
  "provider_settings": {
    "client_type": "ecs_ram_role"
  },
  "annotations": {
    "version_stage": "",
    "version_id": ""
  }
}
EOF

ak_id=$(echo "sealed.fakeheader.$(cat sealed-secret-akid.json | base64 -w0).fakesignature")

cat << EOF > sealed-secret-aksecret.json
{
  "version": "0.1.0",
  "type": "vault",
  "name": "${ak_secret_vault_id}",
  "provider": "aliyun",
  "provider_settings": {
    "client_type": "ecs_ram_role"
  },
  "annotations": {
    "version_stage": "",
    "version_id": ""
  }
}
EOF

ak_secret=$(echo "sealed.fakeheader.$(cat sealed-secret-aksecret.json | base64 -w0).fakesignature")

cat << EOF > gocryptfs.json
{
  "version": "0.1.0",
  "type": "vault",
  "name": "${gocrypt_fs_password}",
  "provider": "aliyun",
  "provider_settings": {
    "client_type": "ecs_ram_role"
  },
  "annotations": {
    "version_stage": "",
    "version_id": ""
  }
}
EOF

gocryptfs_password=$(echo "sealed.fakeheader.$(cat gocryptfs.json | base64 -w0).fakesignature")
target=/tmp/qwen-model
tee <<EOF > mount.json
{
    "driver": "",
    "driver_options": [
        "alibaba-cloud-oss={\"akId\":\"${ak_id}\",\"akSecret\":\"${ak_secret}\",\"annotations\":\"\",\"bucket\":\"${bucket}\",\"encrypted\":\"gocryptfs\",\"encPasswd\":\"${gocryptfs_password}\",\"kmsKeyId\":\"\",\"otherOpts\":\"-o max_stat_cache_size=0 -o allow_other\",\"path\":\"/qwen\",\"readonly\":\"\",\"targetPath\":\"${target}\",\"url\":\"https://oss-cn-beijing.aliyuncs.com\",\"volumeId\":\"\"}"
    ],
    "source": "",
    "fstype": "",
    "options": [],
    "mount_point": "${target}"
}
EOF

echo do mount to ${target} ...

mkdir -p ${target}

cdh-tool secure-mount --storage-path mount.json

echo mount succeeded.

echo launch Qwen Server...
docker rm -f envoy_librats_container_server_qwen qwen > /dev/null 2>&1
docker run \
  -v /tmp/qwen-model:/home/Qwen-7B-Chat \
  --net=host \
  --name qwen \
  -d intelcczoo/qwen:latest \
  python3.10 web_demo.py \
  --checkpoint-path /home/Qwen-7B-Chat/ \
  --cpu-only \
  --server-port 8666 \
  --share

echo launch TNG Server...
docker run -d \
    --name envoy_librats_container_server_qwen \
    --net=host --device=/dev/tdx_guest \
    -v server-ws.yaml:/home/envoy-demo-tls-server-ws.yaml \
    -v kbs/config/sgx_default_qcnl.conf:/etc/sgx_default_qcnl.conf \
    xynnn007/envoy:light \
    envoy-static \
    -c /home/envoy-demo-tls-server-ws.yaml  \
    -l off \
    --component-log-level upstream:error,connection:debug > /dev/null 2>&1

echo do clean...
rm -f gocryptfs.json \
  sealed-secret-aksecret.json \
  sealed-secret-akid.json \
  mount.json