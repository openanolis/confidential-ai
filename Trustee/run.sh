#!/bin/bash
set -e

export $(grep -v '^#' ../.env | xargs)

dnf install -y git wget unzip

# 1. Setup Trustee
REPO_URL=https://github.com/openanolis/trustee.git
# TAG=v1.0.1
COMMIT=17e0f5b356cbd1832d06d0021ad7abaa76767b9c

if [ ! -d "./trustee" ]; then
    if [ -n "${TAG}" ]; then
        git clone --branch ${TAG} ${REPO_URL}
    # elif [ -n "${COMMIT}" ]; then
    #     git clone --depth 1 --no-checkout ${REPO_URL}
    #     git fetch --depth 1 origin ${COMMIT}
    #     git checkout ${COMMIT}
    else
        git clone ${REPO_URL}
    fi
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

docker compose --env-file ../../.env up -d

cd ..

# 2. Download and encrypt model
MODEL=${MODEL_TYPE}
MODEL_FILE=gocryptfs-model
PASSWORD=${GOCRYPTFS_PASSWORD}
PASSWORD_FILE=gocryptfs-password

mkdir -p data
cd data

if ! command -v gocryptfs >/dev/null 2>&1; then
    mkdir gocryptfs && cd gocryptfs
    wget https://github.com/rfjakob/gocryptfs/releases/download/v2.4.0/gocryptfs_v2.4.0_linux-static_amd64.tar.gz \
    tar xf gocryptfs_v2.4.0_linux-static_amd64.tar.gz \
    sudo install -m 0755 ./gocryptfs /usr/local/bin
    cd .. && rm -rf gocryptfs
fi

echo "${PASSWORD}" > ${PASSWORD_FILE}
if [ ! -d "./mount" ]; then
    mkdir ./mount
    cd mount
    mkdir -p cipher plain
    cat ../${PASSWORD_FILE} | gocryptfs -init cipher
    cat ../${PASSWORD_FILE} | gocryptfs cipher plain
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

mkdir -p ../model && \
tar cvzf - -C ./cipher . | split -d -b 2G - "../model/${MODEL_FILE}.tar.gz.part"

cd ..

# 3. Upload encrypted model and password to KBS
KEY_PATH=${KBS_KEY_PATH}
MODEL_DIR=${KBS_MODEL_DIR}
TRUSTEE_URL=${TRUSTEE_ADDR}

echo "upload '$PASSWORD_FILE' to KBS with path: $KEY_PATH"
./trustee-client --url ${TRUSTEE_URL} config --auth-private-key ../trustee/kbs/config/private.key set-resource --path ${KEY_PATH} --resource-file ${PASSWORD_FILE}

for part in ./model/*; do
    filename=$(basename "$part")
    echo "upload '$filename' to KBS with path: $MODEL_DIR$filename"
    ./trustee-client --url ${TRUSTEE_URL} config --auth-private-key ../trustee/kbs/config/private.key set-resource --path ${MODEL_DIR}${filename} --resource-file ./model/${filename}
done

 # WARNING: "allow_all.rego" can only be used in dev environment
POLICY_FILE="allow_all.rego"
cat <<EOF > ${POLICY_FILE}
package policy

default allow = true
EOF
./trustee-client --url ${TRUSTEE_URL} config --auth-private-key ../trustee/kbs/config/private.key set-resource-policy --policy-file ${POLICY_FILE}

cd ..
