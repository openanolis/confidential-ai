# Release Notes

## Confidential AI v1.1.0 (2025-08-01)

1. Overview

Incremental feature and robustness release expanding attestation coverage, strengthening zero-trust networking, and simplifying bootstrapping and operations for AI workloads.

2. Component baselines

Trustee 1.5.1, Trustiflux 1.3.1, TNG 2.2.4.

3. What’s New

- Broader attestation: end-to-end TDX + GPU attestation; default TPM evidence parsing with AK/quote; AA Eventlog/CCEL parsing; TPM verifier fixes.
- Stronger boot trust and config: dracut integration fixes (incl. non-TDX) and removal of sysinit.target dependency; environment-based configuration for CoCoAS/KBS endpoints and policy IDs.
- Richer identity and audit: Attestation Agent propagates instance information; gateway adds claims to audits, HTTPS support, record counts, and automatic cleanup.
- Lightweight gateway mode: in-memory SQLite with shared cache for ephemeral or high-throughput deployments.
- Zero-trust networking: TNG 2.2.4 stable adds SOCKS5 ingress, sanitizes HTTP proxy forwarding, and updates TLS to accept larger X.509 certificates.
- Reliability and ops: improved KBS error codes, packaging/CI/RPM/Docker enhancements, embedded version metadata, expanded unit tests, and assorted bug fixes.


## Confidential AI v1.0.0 (2025-06-01)

1. Overview

- First General Availability release delivering an end-to-end confidential computing solution for AI workloads.

2. Component baselines

Trustee 1.1.3, Trustiflux 1.1.0, TNG 1.0.3.

3. What’s New

- Unified trust plane with CDH/AA integration for remote attestation and resource security across confidential containers.
- Zero-trust data paths via an attestation-anchored gateway enabling end-to-end encryption without application changes.
- Trusted workload lifecycle with built-in TEE verification and secure secret/key delivery for bootstrap and runtime.
- Hardware-rooted assurance through TPM-based attestation and private-key CA integration.
- Standardized attestation/control by migrating the legacy RACR protocol to CDH.
- Boot-time trust establishment via an AA/CDH dracut module.
- Operations: new authentication policy query API for centralized policy visibility and automation.