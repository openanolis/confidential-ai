#!/bin/bash

docker compose -f ./trustiflux/docker-compose.yml down

fusermount -u /tmp/plaintext-model
rm -rf /tmp/plaintext-model
rm -rf /tmp/encrypted-model

if [ -d "./data" ]; then
    rm -rf ./data
fi