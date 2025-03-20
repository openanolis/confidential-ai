# Quick Start

## Introduction

Quick start guides you through the basic verification process of Confidential-AI, which includes the following steps:

1. Deploying Trustee as a user-controlled component that stores sensitive data.
2. Encrypting the model file, uploading the encrypted model to Trustee, and saving the encryption key in Trustee.
3. Deploying Trustiflux as a trusted component in the cloud.
4. Verifying the cloud environment through remote attestation, obtaining the encryption key and the encrypted model from Trustee, and decrypting the model to mount in a trusted environment.

According to the threat model, the first two steps occur on the user side, while the last two steps happen in the cloud. However, for the sake of demonstration, the process shown in this document is based on the same Alibaba Cloud TDX ECS and utilizes a local network.

## Environment Preparation

- Alibaba Cloud TDX ECS: Refer to the “Creating TDX Instances” section in [TDX Confidential Computing Environment guide](https://help.aliyun.com/zh/ecs/user-guide/build-a-tdx-confidential-computing-environment) and it's recommended to create it via the console.

## Configuring and Starting Trustee

### Enable Docker Experimental Features

(Enabling Docker experimental features allows us to use oras)

1. Edit the Docker Configuration File

The Docker configuration file is typically located at `/etc/docker/daemon.json`. You can open this file with any text editor (such as `nano` or `vim`). If the file does not exist, you can create a new one.  

```shell
sudo vim /etc/docker/daemon.json
```

2. Add Experimental Features Configuration

In the `daemon.json` file, add the following content to enable experimental features.

```daemon.json
{
    "experimental": true
}
```

3. Restart the Docker Service

```shell
sudo systemctl restart docker
```

### Configure Alibaba Cloud PCCS

1. Run the command below to automatically configure Alibaba Cloud PCCS for Alibaba Cloud ECS.

```shell
token=$(curl -s -X PUT -H "X-aliyun-ecs-metadata-token-ttl-seconds: 5" "http://100.100.100.200/latest/api/token")
region_id=$(curl -s -H "X-aliyun-ecs-metadata-token: $token" http://100.100.100.200/latest/meta-data/region-id)

# Set PCCS_URL to point to the PCCS in the instance's region
PCCS_URL=https://sgx-dcap-server-vpc.${region_id}.aliyuncs.com/sgx/certification/v4/
sudo bash -c 'cat > /etc/sgx_default_qcnl.conf' << EOF
# PCCS server address
PCCS_URL=${PCCS_URL}
# To accept insecure HTTPS cert, set this option to FALSE
USE_SECURE_CERT=FALSE
EOF
```

### Run Trustee

1. Download the Confidential-AI code.

```shell
git clone https://github.com/inclavare-containers/Confidential-AI.git
```

2. (Optional) Configure the `Confidential-AI/.env` file. Non-empty fields must match the Trustiflux-side configuration.
- `MODEL_TYPE`: Model type, currently supports helloworld;
- `GOCRYPTFS_PASSWORD`: Encryption key string;
- `KBS_KEY_PATH`: Path to the encrypted key in Trustee;
- `KBS_MODEL_DIR`: Path to the encrypted model in Trustee;
- `TRUSTEE_ADDRESS`: Service address of Trustee.

3. Navigate to the Trustee folder and run the `run.sh` file.

```shell
cd Confidential-AI/Trustee
./run.sh
```

## Configuring and Starting Trustiflux

### Run Trustiflux

1. Download the Confidential-AI code.

```shell
git clone https://github.com/inclavare-containers/Confidential-AI.git
```

2. (Optional) Configure the `Confidential-AI/.env` file. Non-empty fields must match the Trustee-side configuration.
- `MODEL_TYPE`: Model type, currently supports helloworld;
- `GOCRYPTFS_PASSWORD`: Leave empty; it will be obtained from Trustee via remote attestation;
- `KBS_KEY_PATH`: Path to the encrypted key in Trustee;
- `KBS_MODEL_DIR`: Path to the encrypted model in Trustee;
- `TRUSTEE_ADDRESS`: Service address of Trustee.

3. Navigate to the Trustiflux folder and run the `run.sh` file.  

```shell
cd Confidential-AI/Trustiflux
./run.sh
```

## Requesting Model Application

On the Trustee side, execute the following command to send a request to Trustiflux via the TNG trusted channel:

```shell
curl http://127.0.0.1:9001/
```

The example web service deployed on the Trustiflux side will return a list of decrypted model files. If the CAI deployment is successful, you should see a response similar to the following:

```shell
{
  "timestamp": "2025-03-20T07:28:07.718523",
  "total_files": 2,
  "files": [
    "helloworld/hello.txt",
    "helloworld/world.txt"
  ]
}
```

## Troubleshooting

1. Image Pulling is Slow or Fails

Configure image acceleration based on Alibaba Cloud ACR. Refer to the official image acceleration documentation.

2. Failed to Automatically Configure Alibaba Cloud PCCS

You can configure it manually. If you have correctly created the Alibaba Cloud TDX ECS according to the preparation instructions, the region for your instance should be North China 2 (Beijing), i.e., `cn-beijing`. Manually create the `/etc/sgx_default_qcnl.conf` file and write the following content.

```shell
# PCCS server address
PCCS_URL=https://sgx-dcap-server.cn-beijing.aliyuncs.com/sgx/certification/v4/
# To accept insecure HTTPS cert, set this option to FALSE
USE_SECURE_CERT=FALSE
```

3. Failed to Run run.sh

First run the `clean.sh` file in the same directory, then run `run.sh`.