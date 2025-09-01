# Confidential AI

Confidential AI开源项目让开发者能够在云端安全执行敏感AI任务：无需暴露原始数据/模型，借助可信硬件、远程证明等技术，实现在不信任环境中保护用户隐私数据、训练集和生成式模型的全流程防护，同时正常调用云计算资源完成复杂AI推理和训练。

<!-- [![CI Status](https://github.com/your-org/your-solution/actions/workflows/ci.yml/badge.svg)](https://github.com/your-org/your-solution/actions) -->
<!-- [![Docker Pulls](https://img.shields.io/docker/pulls/your-image)](https://hub.docker.com/r/your-image) -->
<!-- [![System Architecture](https://img.shields.io/badge/architecture-diagram-blueviolet)](docs/architecture.png) -->

## 目录

- [核心组件](#核心组件)
- [快速部署](#快速部署)
- [许可证](#许可证)

## 核心组件

**当前稳定版**：`v1.1.0` - 2025-08-01

| 组件          | 版本     | 功能描述                    | 完整变更日志 |
|---------------|----------|----------------------------|-----------|
| Trustiflux   | 1.3.1    | 集成CDH、AA，为机密计算容器提供资源安全管控与远程证明服务 | [Trustiflux 发型版本](https://github.com/inclavare-containers/guest-components/releases) |
| Trustee      | 1.5.1    | 包含用于验证机密计算TEE (Trust Execute Evironment) 和为其下发秘密数据的工具与组件 | [Trustee 发型版本](https://github.com/openanolis/trustee/releases) |
| TNG          | 2.2.4    | 基于远程证明的可信网关，无需改造现有应用实现零信任架构的端到端加密通信 | [TNG 发型版本](https://github.com/inclavare-containers/TNG/releases) |

**历史版本**：详见 [版本发布说明](docs/RELEASE_NOTES.md)

**版兼容信息**：详见 [版本兼容信息](docs/VERSIONS.md)

<!-- ## 功能特性 -->

<!-- - **核心功能1**：描述 + 技术亮点（例如：基于TensorFlow Lite的实时推理）
- **核心功能2**：异步任务处理 + 性能指标（例如：每秒处理10k+请求）
- **扩展能力**：插件系统/自定义模块支持
- **跨平台**：支持Windows/Linux/macOS/Docker -->

## 快速部署

### docker部署：

1. 如需快速验证 Confidential-AI 的端到端流程，我们提供了基于 Docker 的一键化部署方案，详见 [Docker 部署指南](deployment/docker/README-zh_CN.md)。该方案适用于以下场景：

- 混合环境模拟：流程涵盖用户侧（Trustee 密钥管理）与云端（Trustiflux 可信推理）的协作，通过 Docker 可在单台 TDX 实例中完整模拟，便于开发调试或演示验证。
- 开箱即用：容器化封装依赖环境和配置脚本，避免因环境差异导致的部署问题，确保流程一致性。

2. 核心要求

- 支持 TDX 的机密计算环境（如阿里云 TDX ECS）。
- 已安装 Docker 及基础命令行工具。

3. 优势特性

- 安全增强：结合 TDX 远程证明技术，确保密钥仅在经过验证的可信环境中解密，保障模型隐私。
- 敏捷交付：预置自动化脚本处理 PCCS 配置、服务发现等复杂步骤，降低上手成本。
- 环境无绑定：容器镜像可在任意支持 TDX 的云环境中快速迁移，适配多云/混合云架构。

### rpm部署：

1. 基于 RPM 包的生产级部署方案，详见 [RPM 部署指南](deployment/rpm/README-zh_CN.md)，适用于以下场景：

- **生产环境部署**：通过标准软件包管理器进行版本控制和依赖管理。
- **硬件专用环境**：直接在支持 TDX 的物理机或虚拟机上部署，获得更优性能。

2. 核心要求

- 支持 TDX 的机密计算环境（如阿里云 TDX ECS）。
- 操作系统为 Alibaba Cloud Linux 3（AL3）。

3. 优势特性

- **标准包管理**：通过 RPM 包进行安装/升级/卸载操作，符合企业运维规范。
- **自动化流程**：预置脚本自动处理密钥管理、服务注册等复杂流程。
- **灵活扩展**：支持自定义配置参数，可通过修改 `config_trustee.yaml` 和 `config_trustiflux.yaml` 调整部署策略。

## 许可证

[![Apache 2.0 License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

本项目采用 Apache 2.0 许可证。
