#!/bin/bash

set -e

if [ "$#" -ne 5 ]; then
  cat <<-EOF

Usage:
    $0 \\
        <TRUSTEE_URL> \\
        <CDH_KEY_ID>

Example:
    $0 \\
        "http://alb-g1hpfiq3zjy42hkmhw.cn-hangzhou.alb.aliyuncs.com/trustee" \\
        "kbs:///default/apsara-cc-cai/model-decryption-key"
EOF

exit 1
fi

export TRUSTEE_URL=$1
export CDH_KEY_ID=$2

envsubst < docker-compose-template.yml > docker-compose.yml

echo "Generated at ./docker-compose.yml"
