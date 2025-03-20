#!/bin/bash

docker compose --env-file ../.env -f ./trustee/docker-compose.yml down

if [ -d "./trustee" ]; then
    rm -rf ./trustee
fi

if [ -d "./data" ]; then
    fusermount -u ./data/mount/plain
    rm -rf ./data
fi
