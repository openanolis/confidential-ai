#!/bin/bash

if [ "$#" -ne 3 ]; then
  cat <<-EOF
Usage:
  - ./encrypt-model.sh <model-path> <oss-bucket> <password-file>

Example:
    ./encrypt-model.sh  ./ai-model oss://jiuzhong-tdx-cai ./password
EOF

  exit -1
fi

model_path=$1
oss_path=$2
password_file=$3

cwd=$(pwd)
# create work dir
mkdir -p ./mount
cd mount
mkdir cipher plain

# initialize gocryptfs
cat ${cwd}/${password_file} | gocryptfs -init cipher

# mount to plain
cat ${cwd}/${password_file} | gocryptfs cipher plain

# move AI model to ./plain
echo encrypt the model
cp -r ${cwd}/${model_path}/* plain

# echo upload the encrypted model
ossutil64 cp -r $(pwd)/cipher/ ${oss_path}
umount $(pwd)/plain
rm -rf cipher plain