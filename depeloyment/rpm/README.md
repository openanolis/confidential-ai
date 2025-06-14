# Quick Start

## Preface

This document guides you through the Confidential-AI deployment verification process based on RPM packages. The process includes the following core steps:

1. Deploy the Trustee service as a user-side confidential data management component.
2. Encrypt model files and expose them via a web service.
3. Deploy the Trustiflux component to implement a cloud-side trusted environment.
4. Obtain keys through remote attestation and decrypt models.

> Note: This document's demonstration workflow is based on Alibaba Cloud TDX ECS instances.

## Environment Preparation

- Alibaba Cloud TDX ECS instance (recommended to create via [console](https://help.aliyun.com/zh/ecs/user-guide/build-a-tdx-confidential-computing-environment))
- Operating system: Alibaba Cloud Linux 3 (AL3)

## Trustee Configuration and Deployment

### RPM Deployment and Execution

1. Clone the code repository
```bash
git clone https://github.com/inclavare-containers/Confidential-AI.git
```

2. Modify the configuration file (optional)
Edit `Confidential-AI/depeloyment/rpm/config_trustee.yaml` to adjust the following parameters:
- `resource_writer.params.model_type`: Model type (DeepSeek-R1-Chat|Qwen-7B-Instruct)
- `secret_writer.params.kbs_addr`: KBS service address
- `secret_writer.params.resource_file`: Key file path

3. Execute the deployment script
```bash
cd Confidential-AI/depeloyment/rpm
./run_trustee.sh
```

## Trustiflux Configuration and Deployment

### RPM Deployment and Execution

1. Clone the code repository (if not already completed)
```bash
git clone https://github.com/inclavare-containers/Confidential-AI.git
```

2. Modify the configuration file (optional)
Edit `Confidential-AI/depeloyment/rpm/config_trustiflux.yaml` to adjust the following parameters:
- `secret_reader.params.kbs_addr`: KBS service address
- `secret_reader.params.as_addr`: Attestation Service address
- `resource_reader.params.url`: Encrypted model web service address

3. Execute the deployment script
```bash
cd Confidential-AI/depeloyment/rpm
./run_trustiflux.sh
```

## Service Verification

After Trustiflux starts, verify the service status using the following method:
```bash
# Check mount points
mount | grep "/tmp/confidential-ai/rpm/trustiflux/mount"
```

## Troubleshooting

### Model Download Failure
```bash
# Clean partial download files
rm -f /tmp/confidential-ai/rpm/trustee/mount/plain/*.tmp

# Re-execute deployment script
./run_trustee.sh
```

### Encrypted File System Mount Failure
```bash
# Force unmount mount point
fusermount -u /tmp/confidential-ai/rpm/trustee/mount/plain

# Clean mount directory
rm -rf /tmp/confidential-ai/rpm/trustee/mount

# Re-deploy
./run_trustee.sh