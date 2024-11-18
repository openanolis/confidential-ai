# 快速启动

## 前言

本文档指导你验证SecureAI的基本流程，该流程包括以下几个步骤。
1. 部署Trustee，作为用户控制的、保存机密数据的组件；
2. 加密模型文件，上传该加密模型到阿里云OSS，并将加密密钥保存在Trustee；
3. 部署Trustiflux，作为云端可信组件；
4. 经过远程证明验证云端环境，从Trustee获取加密密钥，并从阿里云OSS下载加密模型，将其解密后挂载在可信环境中。

根据威胁模型，前两个步骤在用户侧发生，后两个步骤在云端发生。不过为了方便演示，本文档展示的流程基于同一台阿里云TDX ECS，并且使用本地网络。

## 环境准备

- 阿里云TDX ECS：参考[构建TDX机密计算环境](https://help.aliyun.com/zh/ecs/user-guide/build-a-tdx-confidential-computing-environment)中“创建TDX实例”章节，推荐通过控制台创建。
- 阿里云OSS：开通[阿里云OSS服务](https://oss.console.aliyun.com/overview)。
- 阿里云账号访问密钥：参考[创建AccessKey](https://help.aliyun.com/zh/ram/user-guide/create-an-accesskey-pair)，获取并保存Access Key和Access Secret。

## 配置和启动Trustee

### 启用Docker试验性功能

（启用Docker试验性功能让我们可以使用oras）

1. 编辑 Docker 配置文件

Docker 的配置文件通常为`/etc/docker/daemon.json`。可以使用任意文本编辑器（如 `nano` 或 `vim`）打开该文件。如果文件不存在，可以创建一个新的文件。

```shell
sudo vim /etc/docker/daemon.json
```

2. 添加实验性功能配置

在 `daemon.json` 文件中，添加以下内容以启用实验性功能。

```daemon.json
{
    "experimental": true
}
```

3. 重启 Docker 服务

```shell
sudo systemctl restart docker
```

### 配置阿里云PCCS

1. 运行下方命令即可为阿里云ECS自动配置阿里云PCCS。

```shell
token=$(curl -s -X PUT -H "X-aliyun-ecs-metadata-token-ttl-seconds: 5" "http://100.100.100.200/latest/api/token")
region_id=$(curl -s -H "X-aliyun-ecs-metadata-token: $token" http://100.100.100.200/latest/meta-data/region-id)

# 配置PCCS_URL指向实例所在Region的PCCS
PCCS_URL=https://sgx-dcap-server-vpc.${region_id}.aliyuncs.com/sgx/certification/v4/
sudo bash -c 'cat > /etc/sgx_default_qcnl.conf' << EOF
# PCCS server address
PCCS_URL=${PCCS_URL}
# To accept insecure HTTPS cert, set this option to FALSE
USE_SECURE_CERT=FALSE
EOF
```

### 运行Trustee

1. 下载SecureAI代码。

```shell
git clone https://github.com/inclavare-containers/SecureAI.git
```

2. 将准备好的阿里云账号访问密钥写入`secureAI/.env`文件的对应位置。

3. 进入Trustee文件夹，运行`run.sh`文件。

```shell
cd secureAI/Trustee
./run.sh
```

## 配置和启动Trustiflux

### 运行Trustiflux

1. 下载SecureAI代码。

```shell
git clone https://github.com/inclavare-containers/SecureAI.git
```

2. 将准备好的阿里云账号访问密钥写入`secureAI/.env`文件的对应位置。

3. 进入Trustiflux文件夹，运行`run.sh`文件。

```shell
cd secureAI/Trustiflux
./run.sh
```

## Troubleshooting

1. 镜像拉取缓慢甚至失败

基于阿里云ACR配置镜像加速，参考官方镜像加速。

2. 自动配置阿里云PCCS失败

可以手动配置。如果你根据环境准备中的指导正确创建阿里云TDX ECS，你的实例所属地域应为华北2（北京），即`cn-beijing`。手动创建`/etc/sgx_default_qcnl.conf`文件，并写入下述内容即可。

```shell
# PCCS server address
PCCS_URL=https://sgx-dcap-server.cn-beijing.aliyuncs.com/sgx/certification/v4/
# To accept insecure HTTPS cert, set this option to FALSE
USE_SECURE_CERT=FALSE
```

3. 运行run.sh失败

先运行同目录下的`clean.sh`文件，再运行`run.sh`。
