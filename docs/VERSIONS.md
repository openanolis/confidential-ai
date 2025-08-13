# Confiedntial-AI Version

## Usage Notes

1. **Version Milestones** represent _community-tested combinations_ with notable changes,  
2. **Compatibility Matrix** shows _specific test outcomes_ from CI environments,  which may differ in your deployment context.
3. Always verify combinations in your target environment before adoption.

> **Disclaimer**: This file documents community testing results only.  
> Components are provided "AS IS" without warranty. Maintainers make  
> no representations about suitability for any specific purpose.

## Version Milestones

_Community-verified release points maintained by contributors_

| Release Tag | Component Combination | Updated Date | Key Changes |
|-------------|------------------------------|--------------|--------------------------------------|
| v1.1.0      | Trustee:1.5.1 + Trustiflux:1.3.1 + TNG:2.2.4  | 2025-08-12   | • Enhance trusted computing (TPM/TDX/GPU attestation), optimizing gateway performance (in-memory SQLite/HTTPS), and refining APIs (DELETE method, frontend crypto). <br>• Evolve from foundational modular setup (dracut/TPM) to enhanced attestation (TDX/GPU) and configurable service integration. <br>• Transitioned to cross-platform stability (ARM/x86_64), expanded network capabilities (SOCKS5/HTTP proxy), and streamlined deployment processes. |
| v1.0.0      | Trustee:1.1.3 + Trustiflux:1.1.0 + TNG:1.0.3  | 2025-06-01   | • Initial community release |

## Compatibility Matrix

_CI-validated version combinations_

| Trustee | Trustiflux | TNG | test status | timestamp | Remark |
|---------|------------|-----|-------------|-----------|--------|
| 1.5.1 | 1.3.1 | 2.2.4 | ✅ PASS | 2025-08-12 | ConfidentialAI - v1.1.0 |
| 1.1.3 | 1.1.0 | 1.0.3 | ✅ PASS | 2025-06-01 | ConfidentialAI - v1.0.0 |