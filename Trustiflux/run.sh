#!/bin/bash
set -e

# export $(grep -v '^#' ../.env | xargs)
export $(grep -v '^#' ../.env.local | xargs)

dnf update && dnf install -y git wget unzip

# 1. get encrypted-model from Aliyun OSS
AccessKey=${ACCESS_KEY}
AccessSecret=${ACCESS_SECRET}
BucketName=${BUCKET_NAME}
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
    ossutil_config="[default]\naccessKeyId=${AccessKey}\naccessKeySecret=${AccessSecret}\nregion=cn-beijing"
    echo -e "${ossutil_config}" > /root/.ossutilconfig
fi

cd ..

mkdir -p /tmp/encrypted-model
ossutil cp -r oss://${BucketName}/${MODEL}/ /tmp/encrypted-model

# 2. Setup Trustiflux
Trustee

mkdir -p /tmp/plaintext-model

cd trustiflux
./gen-compose.sh <trustee-url> <decryption-key-id>
# Example:
# ./gen-compose.sh \
#    http://alb-g1hpfiq3zjy42hkmhw.cn-hangzhou.alb.aliyuncs.com/trustee \
#    kbs:///default/apsara-cc-cai/model-decryption-key
docker compose up -d