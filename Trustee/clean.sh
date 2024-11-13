#!/bin/bash

docker compose down

if [ -d "./trustee" ]; then
    rm -rf ./trustee
fi

if [ -d "./data" ]; then
    fusermount -u ./data/mount/plain
    rm -rf ./data
fi