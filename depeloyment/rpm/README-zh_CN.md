# 快速启动

## 前言

本文档指导你完成基于RPM包的Confidential-AI部署验证流程，该流程包含以下核心步骤：

1. 部署Trustee服务，作为用户侧机密数据管理组件
2. 加密模型文件并通过Web服务暴露
3. 部署Trustiflux组件，实现云端可信环境
4. 通过远程证明获取密钥并解密模型

> 注意：本文档演示流程基于阿里云TDX ECS环境

## 环境准备

- 阿里云TDX ECS实例（推荐通过[控制台创建](https://help.aliyun.com/zh/ecs/user-guide/build-a-tdx-confidential-computing-environment)）
- 操作系统为Alibaba Cloud Linux 3（AL3）

## Trustee配置与部署

### RPM部署与运行

1. 克隆代码仓库
```bash
git clone https://github.com/inclavare-containers/Confidential-AI.git
```

2. 修改配置文件（可选）
编辑`Confidential-AI/depeloyment/rpm/config_trustee.yaml`调整以下参数：
- `resource_writer.params.model_type`：模型类型（DeepSeek-R1-Chat|Qwen-7B-Instruct）
- `secret_writer.params.kbs_addr`：KBS服务地址
- `secret_writer.params.resource_file`：密钥文件路径

3. 执行部署脚本
```bash
cd Confidential-AI/depeloyment/rpm
./run_trustee.sh
```

## Trustiflux配置与部署

### RPM部署与运行

1. 克隆代码仓库（如尚未完成）
```bash
git clone https://github.com/inclavare-containers/Confidential-AI.git
```

2. 修改配置文件（可选）
编辑`Confidential-AI/depeloyment/rpm/config_trustiflux.yaml`调整以下参数：
- `secret_reader.params.kbs_addr`：KBS服务地址
- `secret_reader.params.as_addr`：Attestation Service地址
- `resource_reader.params.url`：加密模型Web服务地址

3. 执行部署脚本
```bash
cd Confidential-AI/depeloyment/rpm
./run_trustiflux.sh
```

## 服务验证

Trustiflux启动后，可通过以下方式验证服务状态：
```bash
# 查看挂载点
mount | grep "/tmp/confidential-ai/rpm/trustiflux/mount"
```

## 故障排查

### 模型下载失败
```bash
# 清理部分下载文件
rm -f /tmp/confidential-ai/rpm/trustee/mount/plain/*.tmp

# 重新执行部署脚本
./run_trustee.sh
```

### 加密文件系统挂载失败
```bash
# 强制卸载挂载点
fusermount -u /tmp/confidential-ai/rpm/trustee/mount/plain

# 清理挂载目录
rm -rf /tmp/confidential-ai/rpm/trustee/mount

# 重新执行部署
./run_trustee.sh
```

## 常见问题

1. 使用 pip3 安装依赖失败
问题现象：可能报错找不到符合要求的版本，或连接超时等。
问题原因：通常是网络问题，导致依赖下载失败或无法访问。
解决方法：可以通过使用国内镜像源加速下载来解决。例如使用阿里源下载：`pip3 install -i https://mirrors.aliyun.com/pypi/simple/ your-packeage`