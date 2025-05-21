#!/bin/bash
set -e

export $(grep -v '^#' ../.env | xargs)

dnf install -y git wget unzip

# 1. Setup Trustee
REPO_URL=https://github.com/openanolis/trustee.git
TAG=v1.1.1
# COMMIT=17e0f5b356cbd1832d06d0021ad7abaa76767b9c

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
    wget https://github.com/rfjakob/gocryptfs/releases/download/v2.4.0/gocryptfs_v2.4.0_linux-static_amd64.tar.gz
    tar xf gocryptfs_v2.4.0_linux-static_amd64.tar.gz
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

if [ "${MODEL}" = "DeepSeek-R1-Chat" ]; then
    if [ ! -f "./plain/DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf" ]; then
        wget -c --progress=dot:giga --show-progress --tries=30 --timeout=30 --waitretry=15 -P ./plain \
            https://modelscope.cn/models/unsloth/DeepSeek-R1-Distill-Qwen-7B-GGUF/resolve/master/DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf \
            || { echo "model ${MODEL} download failed"; exit 1; }
    fi
    echo "model ${MODEL} download success."
elif [ "${MODEL}" = "Qwen-7B-Instruct" ]; then
    if [ ! -f "./plain/qwen2.5-7b-instruct-q4_k_m.gguf" ]; then
        wget -c --progress=dot:giga --show-progress --tries=30 --timeout=30 --waitretry=15 -P ./plain \
            https://modelscope.cn/models/Qwen/Qwen2.5-7B-Instruct-GGUF/resolve/master/qwen2.5-7b-instruct-q4_k_m.gguf \
            || { echo "model ${MODEL} download failed"; exit 1; }
    fi
    echo "model ${MODEL} download success."
    exit 1
else
    echo "model ${MODEL} not supported."
    exit 1
fi

mkdir -p ../model && \
tar cvzf - -C ./cipher . | split -d -b 1G - "../model/${MODEL_FILE}.tar.gz.part"

cd ..

# 3. Upload password to KBS and set KBS policy
KEY_PATH=${KBS_KEY_PATH}
TRUSTEE_URL=${TRUSTEE_ADDR}

echo "upload '$PASSWORD_FILE' to KBS with path: $KEY_PATH"
./trustee-client --url ${TRUSTEE_URL} config --auth-private-key ../trustee/kbs/config/private.key set-resource --path ${KEY_PATH} --resource-file ${PASSWORD_FILE}

 # WARNING: "allow_all.rego" can only be used in dev environment
POLICY_FILE="allow_all.rego"
cat <<EOF > ${POLICY_FILE}
package policy

default allow = true
EOF
./trustee-client --url ${TRUSTEE_URL} config --auth-private-key ../trustee/kbs/config/private.key set-resource-policy --policy-file ${POLICY_FILE}

# 4. open encrypted model for web access
MODEL_PORT=${ENCRYPT_MODEL_PORT}

cd model

if command -v python3 &> /dev/null; then
    SERVER_CMD="python3 -m http.server $MODEL_PORT --bind 0.0.0.0"
else
    SERVER_CMD="python -m SimpleHTTPServer $MODEL_PORT --bind 0.0.0.0"
fi

echo "[+] Starting Temporary Web Service:"
echo "    Directory: $(realpath $DIRECTORY)"
echo "    Address: http://0.0.0.0:$MODEL_PORT"
echo "    Stop: Ctrl+C"

$SERVER_CMD