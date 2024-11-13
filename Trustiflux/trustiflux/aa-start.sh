#!/bin/bash

set -euo pipefail
set -o noglob

# Initialize parameters
trustee_address=''
as_addr=''

usage() {
  echo "This script is used to start Attestation Agent" 1>&2
  echo "" 1>&2
  echo "Usage: $0 --trustee-addr Address of remote trustee" 1>&2

  exit 1
}

# Parse cmd
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --as-addr)
      as_addr="$2"
      shift 2
      ;;
    --trustee-addr)
      trustee_address="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

cat << EOF > /etc/attestation-agent.toml
[token_configs]
[token_configs.coco_as]
url = "${as_addr}"

[token_configs.kbs]
url = "${trustee_address}"
EOF

attestation-agent -c /etc/attestation-agent.toml