#!/bin/bash
set -e

export $(grep -v '^#' ../.env | xargs)

dnf install -y git wget unzip

# 1. Download and encrypt model
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
elif [ "${MODEL}" = "Qwen3-0.6B" ]; then
    if [ ! -f "./plain/Qwen3-0.6B-Q8_0.gguf" ]; then
        wget -c --progress=dot:giga --show-progress --tries=30 --timeout=30 --waitretry=15 -P ./plain \
            https://modelscope.cn/models/Qwen/Qwen3-0.6B-GGUF/resolve/master/Qwen3-0.6B-Q8_0.gguf \
            || { echo "model ${MODEL} download failed"; exit 1; }
    fi
    echo "model ${MODEL} download success."
else
    echo "model ${MODEL} not supported."
    exit 1
fi

mkdir -p ../model && \
tar cvzf - -C ./cipher . | split -d -b 1G - "../model/${MODEL_FILE}.tar.gz.part"

cd ../..

# 2. Setup Trustee
REPO_URL=https://github.com/openanolis/trustee.git
TAG=v1.6.0
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

# Upload password to KBS
KEY_PATH=${KBS_KEY_PATH}
TRUSTEE_URL=${TRUSTEE_ADDR}

echo "place '$PASSWORD_FILE' to KBS with path: $KEY_PATH"
mkdir -p "kbs/data/kbs-storage/${KBS_KEY_PATH%/*}"
cp "../data/${PASSWORD_FILE}" "kbs/data/kbs-storage/${KBS_KEY_PATH}"

# set as config
jq '.attestation_token_broker.type = "Ear"' \
  ./kbs/config/as-config.json > /tmp/as-config.json.tmp \
  && mv /tmp/as-config.json.tmp ./kbs/config/as-config.json

# set policy
###### Optimized policy setting for TDX / CSV with separate policy files
# Check hardware security environment and set appropriate policy
if [[ -e /dev/tdx_guest ]]; then
    echo "Detected: TDX guest environment (/dev/tdx_guest present)"
    mkdir -p kbs/config/docker-compose
    cp ../policy/tdx/kbs_policy.rego kbs/config/docker-compose/policy.rego
elif [[ -e /dev/csv-guest ]]; then
    echo "Detected: CSV guest environment (/dev/csv-guest present)"
    mkdir -p kbs/config/docker-compose kbs/data/attestation-service/token/ear/policies/opa
    cp ../policy/csv/kbs_policy.rego kbs/config/docker-compose/policy.rego
    cp ../policy/csv/default_cpu.rego kbs/data/attestation-service/token/ear/policies/opa/default_cpu.rego
    cp ../policy/csv/default_dcu.rego kbs/data/attestation-service/token/ear/policies/opa/default_dcu.rego
else
    echo "No /dev/tdx_guest or /dev/csv-guest found; not a TDX/CSV guest or drivers not loaded."
    echo "Use default policy (allow=all), default policy should only be used in development environment."
    # do nothing
fi

# start trustee
docker compose --env-file ../../.env up -d

cd ..

# 3. open encrypted model for web access
MODEL_PORT=${ENCRYPT_MODEL_PORT}

cd data/model

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
