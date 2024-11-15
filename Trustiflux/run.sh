#!/bin/bash
set -e

# export $(grep -v '^#' ../.env | xargs)
export $(grep -v '^#' ../.env | xargs)

dnf install -y git wget unzip

# 1. get encrypted-model from Aliyun OSS
AK=${ACCESS_KEY}
AS=${ACCESS_SECRET}
BUCKET=${BUCKET_NAME}
MODEL=${MODEL_TYPE}

mkdir -p data
cd data

if ! command -v ossutil >/dev/null 2>&1; then
    mkdir -p ossutil
    cd ossutil

    curl -o ossutil-2.0.4-beta.10251600-linux-amd64.zip https://gosspublic.alicdn.com/ossutil/v2-beta/2.0.4-beta.10251600/ossutil-2.0.4-beta.10251600-linux-amd64.zip
    unzip ossutil-2.0.4-beta.10251600-linux-amd64.zip
    cd ossutil-2.0.4-beta.10251600-linux-amd64
    chmod 755 ossutil
    sudo mv ossutil /usr/local/bin/ && sudo ln -s /usr/local/bin/ossutil /usr/bin/ossutil

    cd ../..
fi
if [ ! -f "/root/.ossutilconfig" ]; then
    ossutil_config="[default]\naccessKeyId=${AK}\naccessKeySecret=${AS}\nregion=cn-beijing"
    echo -e "${ossutil_config}" > /root/.ossutilconfig
fi

cd ..

mkdir -p /tmp/encrypted-model
ossutil cp -r oss://${BUCKET}/${MODEL}/ /tmp/encrypted-model

# 2. Setup Trustiflux
mkdir -p /tmp/plaintext-model

cd trustiflux

# ./gen-compose.sh "${TRUSTEE_URL}" "kbs:///${KEY_PATH}"
docker compose --env-file ../../.env up -d --build