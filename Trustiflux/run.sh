#!/bin/bash
set -e

export $(grep -v '^#' ../.env | xargs)

dnf install -y git wget unzip

# 1. get encrypted-model from KBS
MODEL=${MODEL_TYPE}
MODEL_DIR=${KBS_MODEL_DIR}
MODEL_FILE=gocryptfs-model
TRUSTEE_URL=${TRUSTEE_ADDR}

mkdir -p data
cd data
mkdir -p model

# TODO: upload trustee-client to oras, so we can download it there
cp ../../Trustee/data/trustee-client ./trustee-client
status=true
for i in {00..99}; do
    printf -v filename "%s.tar.gz.part%02d" "$MODEL_FILE" "$((10#$i))"
    kbspath=$(printf "%s/%s" "${MODEL_DIR%/}" "$filename")
    echo "get '$filename' from KBS with path: $kbspath"
    # ./trustee-client --url ${TRUSTEE_URL} get-resource --path ${kbspath}

    tmpfile=$(mktemp) || exit 1
    if ./trustee-client --url "${TRUSTEE_URL}" get-resource --path "${kbspath}" > "${tmpfile}"; then
        if ! base64 -d "${tmpfile}" > "./model/${filename}"; then
            echo "Error: Base64解码失败" >&2
        fi
    else
        echo "Error: 第${i}个资源获取失败 (exit code $?)，请确认是否已获取到全部加密模型资源" >&2
        status=false 
    fi
    rm -f "${tmpfile}"

    if [ "$status" = false ]; then
        break
    fi
done

cd ..

mkdir -p /tmp/encrypted-model
cat ./data/model/${MODEL_FILE}.tar.gz.part* | tar xvzf - -C /tmp/encrypted-model

# 2. Setup Trustiflux
mkdir -p /tmp/plaintext-model

cd trustiflux

docker compose --env-file ../../.env up -d --build