#!/bin/bash
set -e

export $(grep -v '^#' ../.env | xargs)

dnf install -y git wget unzip

# 1. get encrypted-model from user web file service
MODEL=${MODEL_TYPE}
MODEL_FILE=gocryptfs-model
TRUSTEE_URL=${TRUSTEE_ADDR}
MODEL_URL=http://${ENCRYPT_MODEL_IP}:${ENCRYPT_MODEL_PORT}

wget -c --tries=30 --timeout=30 --waitretry=15 -r --progress=dot:giga --show-progress -np -nH -R "index.html*" --cut-dirs=1 -P ./data/model "${MODEL_URL}"

mkdir -p /tmp/encrypted-model
cat ./data/model/${MODEL_FILE}.tar.gz.part* | tar xvzf - -C /tmp/encrypted-model

# 2. Setup Trustiflux, and Trustiflux will do attestation, key retrieval and model decryption. Then LLM app will start.
mkdir -p /tmp/plaintext-model

cd trustiflux

docker compose --env-file ../../.env up -d --build