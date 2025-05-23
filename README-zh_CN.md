# Confidential AI

Confidential AI开源项目让开发者能够在云端安全执行敏感AI任务：无需暴露原始数据/模型，借助可信硬件、远程证明等技术，实现在不信任环境中保护用户隐私数据、训练集和生成式模型的全流程防护，同时正常调用云计算资源完成复杂AI推理和训练。

<!-- [![CI Status](https://github.com/your-org/your-solution/actions/workflows/ci.yml/badge.svg)](https://github.com/your-org/your-solution/actions) -->
<!-- [![Docker Pulls](https://img.shields.io/docker/pulls/your-image)](https://hub.docker.com/r/your-image) -->
<!-- [![System Architecture](https://img.shields.io/badge/architecture-diagram-blueviolet)](docs/architecture.png) -->

---

## 目录

- [核心组件](#核心组件)
- [功能特性](#功能特性)
- [快速部署](#快速部署)
- [配置说明](#配置说明)
- [许可证](#许可证)
- [常见问题](#常见问题)

---

## 核心组件

**当前稳定版**：`v1.0.0` - 2025-06-01
**核心升级**：首次发布 Confidential AI

| 组件          | 版本     | 功能描述                    | 变更摘要 |
|---------------|----------|----------------------------|-----------|
| Trustiflux   | 1.1.0    | 集成CDH、AA，为机密计算容器提供资源安全管控与远程证明服务 | 新增AA/CDH的dracut模块支持<br>架构重构：RCAR协议迁移至CDH<br>安全强化：集成TPM证明模块 |
| Trustee      | 1.1.3    | 包含用于验证机密计算TEE (Trust Execute Evironment) 和为其下发秘密数据的工具与组件 | 集成TPM私钥CA插件<br>新增认证策略查询API |
| TNG          | 1.0.3    | 基于远程证明的可信网关，无需改造现有应用实现零信任架构的端到端加密通信 | - |

**完整变更日志**

[Trustiflux Releases](https://github.com/inclavare-containers/guest-components/releases)
[Trustee Releases](https://github.com/openanolis/trustee/releases)
[TNG Releases](https://github.com/inclavare-containers/TNG/releases)
---

## 功能特性

<!-- - **核心功能1**：描述 + 技术亮点（例如：基于TensorFlow Lite的实时推理）
- **核心功能2**：异步任务处理 + 性能指标（例如：每秒处理10k+请求）
- **扩展能力**：插件系统/自定义模块支持
- **跨平台**：支持Windows/Linux/macOS/Docker -->

---

## 快速部署

### 一键启动（需安装Docker）：
```bash
git clone https://github.com/your-org/your-solution.git
cd your-solution
docker-compose up -d
```

---

## 配置说明


## 许可证

[![Apache 2.0 License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)  
本项目采用 Apache 2.0 许可证。

## 常见问题

<!-- Q: 如何处理内存不足问题？
A: 尝试调整config.yaml中的memory_limit参数或使用分块处理模式

Q: 是否支持ARM架构？
A: 自v2.1.0起提供实验性支持 -->

