# Confidential AI

## File Overview

- `0000-encrypt-model.sh`: Script for encrypting models, requires tools like gocryptfs. See the Preparation section for installation details.
- `0001-ra-service.sh`: Starts the remote attestation service within a trusted execution domain, requires docker-compose.
- `0002-ra-deploy-model.sh`: Launches remote attestation, pulls encrypted models, and starts the Qwen service inside a TDX virtual machine.
- `cdh-config.toml`: Example configuration file for cdh.
- `server-ws.yaml` and `client-ws.yaml`: Configuration files for setting up the server-side and client-side gateways.
- `client.sh`: Script to launch the client application.

## Preparation

To prepare for model encryption, install gocryptfs and ossutil:

```shell
## Install Go
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
go env -w GO111MODULE=on
go env -w GOPROXY=https://goproxy.cn,direct

## Install Gocryptfs
git clone https://github.com/rfjakob/gocryptfs.git
cd gocryptfs
./build-without-openssl.bash
sudo install -m 0755 ./gocryptfs /usr/local/bin

## Install OSS Client
## Installation guide: https://help.aliyun.com/zh/oss/developer-reference/install-ossutil?spm=a2c4g.11186623.0.i3#concept-303829
wget https://gosspublic.alicdn.com/ossutil/1.7.19/ossutil-v1.7.19-linux-amd64.zip
yum install -y unzip
unzip ossutil-v1.7.19-linux-amd64.zip
cd ossutil-v1.7.19-linux-amd64/
cp * /usr/local/bin
cd ..
rm -rf ossutil-v1.7.19-linux-amd64*
```

## Encrypting Models

First, use the `./0000-encrypt-model.sh` script to encrypt the model:
```shell
./0000-encrypt-model.sh <model-path> <oss-bucket> <password-file>
```
Example:
```shell
./0000-encrypt-model.sh ./Qwen-7B-Chat jingyao-tdx-cai ./password
```
This command encrypts the model and uploads it to the OSS service.

## Starting Remote Attestation Service

To start the remote attestation service, run:
```shell
./0001-ra-service.sh
```
Note: This script uses port 8080 by default. You can customize the port number as needed.

## Deploying the Model

Deploy using:
```shell
./0002-ra-deploy-model.sh cai-oss-AccessKeyID cai-oss-AccessKeySecret gocryptfs-password jingyao-tdx-cai /qwen http://127.0.0.1:8080
```
Make sure to replace `cai-oss-AccessKeyID`, `cai-oss-AccessKeySecret`, and `gocryptfs-password` with your credentials. `jingyao-tdx-cai` is the name of your bucket, and `/qwen` is the path within the OSS bucket where the model is stored. `http://127.0.0.1:8080` should match the port number used by your remote attestation service.

## Launching the Client

Finally, launch the client application using:
```shell
./client.sh
```
Ensure `client-ws.yaml` is configured with the correct `socket_address` to indicate the IP address of the target server:
```yaml
socket_address:
  address: {server_ip_addr}
```
