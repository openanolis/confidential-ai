# Confidential AI

The Confidential AI open-source project enables developers to securely execute sensitive AI tasks in the cloud: without exposing raw data/models, it leverages trusted hardware and remote attestation technologies to protect user privacy data, training sets, and generative models throughout their lifecycle while allowing normal utilization of cloud computing resources for complex AI inference and training.

<!-- [![CI Status](https://github.com/your-org/your-solution/actions/workflows/ci.yml/badge.svg)](https://github.com/your-org/your-solution/actions) -->
<!-- [![Docker Pulls](https://img.shields.io/docker/pulls/your-image)](https://hub.docker.com/r/your-image) -->
<!-- [![System Architecture](https://img.shields.io/badge/architecture-diagram-blueviolet)](docs/architecture.png) -->

## Table of Contents

- [Components](#Components)
- [Features](#Features)
- [Deployment](#Deployment)
- [License](#License)

## Components

**Current Stable Version**: `v1.0.0` - 2025-06-01
**Core Update**: First release of Confidential AI

| Component   | Version | Function Description                          | Change Summary |
|-------------|---------|-----------------------------------------------|----------------|
| Trustiflux  | 1.1.0   | Integrates CDH/AA to provide resource security management and remote attestation services for confidential computing containers | Added AA/CDH dracut module support<br>Architecture restructured: RACR protocol migrated to CDH<br>Security enhancements: Integrated TPM attestation module |
| Trustee     | 1.1.3   | Tools and components for verifying confidential computing TEE (Trust Execution Environment) and secret data delivery | Integrated TPM private key CA plugin<br>Added authentication policy query API |
| TNG         | 1.0.3   | Trusted gateway based on remote attestation, enabling end-to-end encrypted communication for zero-trust architecture without application modifications | - |

**Full Change Log**

- [Trustiflux Releases](https://github.com/inclavare-containers/guest-components/releases)
- [Trustee Releases](https://github.com/openanolis/trustee/releases)
- [TNG Releases](https://github.com/inclavare-containers/TNG/releases)

## Features

<!-- - **Core Feature 1**: Description + Technical Highlights (e.g., Real-time inference based on TensorFlow Lite)
- **Core Feature 2**: Asynchronous task processing + Performance metrics (e.g., 10k+ requests per second)
- **Expansion Capabilities**: Plugin system/Custom module support
- **Cross-platform**: Supports Windows/Linux/macOS/Docker -->

## Deployment

### Docker Deployment:

1. For rapid validation of Confidential-AI's end-to-end workflow, we provide a one-click Docker-based deployment solution. See [Docker Deployment Guide](deployment/docker/README.md). This solution applies to:

- Hybrid environment simulation: Process covers user side (Trustee key management) and cloud side (Trustiflux trusted inference) collaboration. Full simulation can be completed in a single TDX instance through Docker, suitable for development debugging or demonstration verification.
- Out-of-the-box: Containerized packaging of dependency environments and configuration scripts avoids deployment issues caused by environment differences, ensuring process consistency.

2. Core Requirements

- Confidential computing environment supporting TDX (e.g., Alibaba Cloud TDX ECS).
- Docker and basic command-line tools installed.

3. Key Advantages

- Security enhancement: Combines TDX remote attestation technology to ensure keys are decrypted only in verified trusted environments, protecting model privacy.
- Agile delivery: Pre-configured automation scripts handle complex steps like PCCS configuration and service discovery, reducing onboarding costs.
- Environment agnosticism: Container images can be rapidly migrated across any cloud environment supporting TDX, adapting to multi-cloud/hybrid cloud architectures.

### RPM Deployment:

1. Production-grade deployment solution based on RPM packages. For details, see [RPM Deployment Guide](deployment/rpm/README.md). Applicable to the following scenarios:

- Production Environment Deployment: Version control and dependency management through standard package managers.
- Hardware-Dedicated Environments: Deploy directly on TDX-supported physical or virtual machines for optimal performance.

2. Core Requirements

- TDX-supported confidential computing environment (e.g., Alibaba Cloud TDX ECS).
- Operating system: Alibaba Cloud Linux 3 (AL3).

3. Key Advantages

- Standard Package Management: Install/upgrade/uninstall via RPM packages, compliant with enterprise operation standards.
- Automated Workflows: Preconfigured scripts automatically handle complex processes like key management and service registration.
- Flexible Extensibility: Support for custom configuration parameters by modifying `config_trustee.yaml` and `config_trustiflux.yaml` to adjust deployment strategies.

## License

[![Apache 2.0 License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

This project uses the Apache 2.0 license.
