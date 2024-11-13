#!/bin/bash

docker compose -f ./trustee/docker-compose.yml down

if [ -d "./trustee" ]; then
    rm -rf ./trustee
fi

if [ -d "./data" ]; then
    fusermount -u ./data/mount/plain
    rm -rf ./data
fi

rm /usr/local/bin/ossutil /usr/bin/ossutil /root/.ossutilconfig

# Also delete Aliyun OSS Bucket manually if necessary.
# Aliyun OSS Bucket link: https://oss.console.aliyun.com/bucket