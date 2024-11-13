#!/bin/bash
set -e

# export $(grep -v '^#' ../.env | xargs)
export $(grep -v '^#' ../.env.local | xargs)

dnf update && dnf install -y git wget unzip

# 1. Setup Trustee
REPO_URL=https://github.com/confidential-containers/trustee.git
TAG=v0.10.1

if [ ! -d "./trustee" ]; then
    git clone --branch ${TAG} ${REPO_URL}
fi
cd trustee

if [ ! -f "./kbs/config/private.key" ]; then
    openssl genpkey -algorithm ed25519 > kbs/config/private.key
    openssl pkey -in kbs/config/private.key -pubout -out kbs/config/public.pub
elif [ ! -f "./kbs/config/public.pub" ]; then
    openssl pkey -in kbs/config/private.key -pubout -out kbs/config/public.pub
fi

cp ../docker-compose.yml ./docker-compose.yml
cp /etc/sgx_default_qcnl.conf ./kbs/config/

docker compose up -d

cd ..

# 2. Download and encrypt model
MODEL=${MODEL_TYPE}
PASSWORD=${GOCRYPTFS_PASSWORD}

mkdir -p data
cd data

if ! command -v gocryptfs >/dev/null 2>&1; then
    mkdir gocryptfs && cd gocryptfs
    wget https://github.com/rfjakob/gocryptfs/releases/download/v2.4.0/gocryptfs_v2.4.0_linux-static_amd64.tar.gz \
    tar xf gocryptfs_v2.4.0_linux-static_amd64.tar.gz \
    sudo install -m 0755 ./gocryptfs /usr/local/bin
    cd .. && rm -rf gocryptfs
fi

echo "${PASSWORD}" > cachefs-password
if [ ! -d "./mount" ]; then
    mkdir ./mount
    cd mount
    mkdir -p cipher plain
    cat ../cachefs-password | gocryptfs -init cipher
    cat ../cachefs-password | gocryptfs cipher plain
    cd ..
fi

cd mount

if [ "${MODEL}" = "helloworld" ]; then
    mkdir -p ./helloworld
    echo "hello" > ./helloworld/hello.txt
    echo "world" > ./helloworld/world.txt
    cp -r ./helloworld ./plain
elif [ "${MODEL}" = "Qwen-7B-Chat"]; then
    # if [ ! -d "./Qwen-7B-Chat" ]; then
    #     dnf install -y git-lfs
    #     git lfs install && git clone https://www.modelscope.cn/qwen/Qwen-7B-Chat.git
    # fi
    # cp -r ./Qwen-7B-Chat ./mount/plain
    echo "model ${MODEL} not supported."
    exit 1
else
    echo "model ${MODEL} not supported."
    exit 1
fi

cd ..

# 3. Upload encrypted model and password to KBS
AK=${ACCESS_KEY}
AS=${ACCESS_SECRET}
BUCKET=${BUCKET_NAME}

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
    OSSUTIL_CONFIG="[default]\naccessKeyId=${AK}\naccessKeySecret=${AS}\nregion=cn-beijing"
    echo -e "${OSSUTIL_CONFIG}" > /root/.ossutilconfig
fi

ossutil mb oss://${BUCKET}
ossutil mkdir oss://${BUCKET}/${MODEL}
ossutil cp -r ./mount/cipher/ oss://${BUCKET}/${MODEL}/

if ! command -v oras >/dev/null 2>&1; then
    VERSION="1.2.0"
    curl -LO "https://github.com/oras-project/oras/releases/download/v${VERSION}/oras_${VERSION}_linux_amd64.tar.gz"
    mkdir -p oras-install/
    tar -zxf oras_${VERSION}_*.tar.gz -C oras-install/
    sudo mv oras-install/oras /usr/local/bin/
    rm -rf oras_${VERSION}_*.tar.gz oras-install/
fi

oras pull ghcr.io/confidential-containers/staged-images/kbs-client:sample_only-x86_64-linux-gnu-68607d4300dda5a8ae948e2562fd06d09cbd7eca
chmod +x ./kbs-client

./kbs-client --url http://127.0.0.1:8080 config --auth-private-key ../trustee/kbs/config/private.key  set-resource --path test/cai/password --resource-file cachefs-password
