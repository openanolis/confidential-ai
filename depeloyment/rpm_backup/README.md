# Quick Start

## Introduction

Quick start guides you through the basic verification process of Confidential-AI, which includes the following steps:

1. Deploying Trustee as a user-controlled component that stores sensitive data.
2. Encrypting the model file, uploading the encrypted model to Trustee, and saving the encryption key in Trustee.
3. Deploying Trustiflux as a trusted component in the cloud.
4. Verifying the cloud environment through remote attestation, obtaining the encryption key and the encrypted model from Trustee, and decrypting the model to mount in a trusted environment.

According to the threat model, the first two steps occur on the user side, while the last two steps happen in the cloud. However, for the sake of demonstration, the process shown in this document is based on the same Alibaba Cloud TDX ECS and utilizes a local network.
