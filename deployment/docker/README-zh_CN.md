# 快速启动

## 前言

本文档指导你验证Confidential-AI的基本流程，该流程包括以下几个步骤。

1. 部署Trustee，作为用户控制的、保存机密数据的组件；
2. 加密模型文件，将该加密模型开放web访问，同时将加密密钥保存在Trustee；
3. 部署Trustiflux，作为云端可信组件；
4. 经过远程证明验证云端环境，从Trustee获取加密密钥，并经过web获取加密模型，将其解密后挂载在可信环境中。

根据威胁模型，前两个步骤在用户侧发生，后两个步骤在云端发生。不过为了方便演示，本文档展示的流程基于同一台阿里云TDX ECS，并且使用本地网络。

## 环境准备

- 阿里云TDX ECS：参考[构建TDX机密计算环境](https://help.aliyun.com/zh/ecs/user-guide/build-a-tdx-confidential-computing-environment)中“创建TDX实例”章节，推荐通过控制台创建。

## 配置和启动Trustee

1. 下载Confidential-AI代码。

```shell
git clone https://github.com/inclavare-containers/Confidential-AI.git
```

2. （可选）配置`Confidential-AI/.env`文件，非空字段需要与Trustiflux侧保持一致。

- `MODEL_TYPE`：模型类型，当前支持`DeepSeek-R1-Chat`|`Qwen-7B-Instruct`；
- `GOCRYPTFS_PASSWORD`: 加密密钥字符串；
- `KBS_KEY_PATH`: Trustee中加密密钥的路径；
- `KBS_MODEL_DIR`: Trustee中加密模型的路径；
- `TRUSTEE_ADDRESS`：Trustee的服务地址。

3. 进入Trustee文件夹，运行`run.sh`文件。

```shell
cd Confidential-AI/Trustee
./run.sh
```

## 配置和启动Trustiflux

1. 下载Confidential-AI代码。

```shell
git clone https://github.com/inclavare-containers/Confidential-AI.git
```

2. （可选）配置`Confidential-AI/.env`文件，非空字段需要与Trustee侧保持一致。

- `MODEL_TYPE`：模型类型，当前支持`Qwen3-0.6B`|`DeepSeek-R1-Chat`|`Qwen-7B-Instruct`；
- `GOCRYPTFS_PASSWORD`: 留空，将经过远程证明从Trustee获取；
- `KBS_KEY_PATH`: Trustee中加密密钥的路径；
- `ENCRYPT_MODEL_IP`: Trustee侧文件Web服务的IP；
- `ENCRYPT_MODEL_PORT`: Trustee侧文件Web服务的端口；
- `TRUSTEE_ADDRESS`: Trustee的服务地址；
- `TRUSTEE_AS_ADDR`: Trustee AS的服务地址。

3. 进入Trustiflux文件夹，运行`run.sh`文件。

```shell
cd Confidential-AI/Trustiflux
./run.sh
```

## 请求模型应用

在Trustee侧，访问如下网址，会基于TNG可信信道，向Trustiflux发起请求，并访问推理Web服务。

```url
http://127.0.0.1:9001/
```

Trustiflux侧部署了推理web服务，如果CAI部署成功，则可以访问到推理web服务界面。

## Troubleshooting

1. 镜像拉取缓慢甚至失败

基于阿里云ACR配置镜像加速，参考官方镜像加速。

2. 运行run.sh失败

先运行同目录下的`clean.sh`文件，再运行`run.sh`。

3. 在CSV环境执行失败

请参考[CSV虚拟机Confidential_AI](https://openanolis.cn/sig/Hygon-Arch/doc/1358389851069644815)，确保CSV环境配置正确。