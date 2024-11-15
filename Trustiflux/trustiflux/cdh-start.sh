#!/bin/bash

set -euo pipefail
set -o noglob

# Initialize parameters
trustee_address=''
key_id=''
resource_path=''

usage() {
  echo "This script is used to start Attestation Agent" 1>&2
  echo "" 1>&2
  echo "Usage: $0 --trustee-addr Address of remote trustee" 1>&2
  echo "--key-id the id of the confidential resource from trustee" 1>&2
  echo "--resource-path the file path that will store the confidential resource" 1>&2

  exit 1
}

# Parse cmd
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --trustee-addr)
      trustee_address="$2"
      shift 2
      ;;
    --key-id)
      key_id="$2"
      shift 2
      ;;
    --resource-path)
      resource_path="$2"
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

if [ -n "${TRUSTEE_ADDR}" ]; then
    trustee_address=${TRUSTEE_ADDR}
fi
if [ -n "${CDH_KEY_ID}" ]; then
    key_id=${CDH_KEY_ID}
fi

cat << EOF > /etc/confidential-data-hub.toml
socket = "unix:///run/confidential-containers/cdh.sock"
[kbc]
name = "cc_kbc"
url = "${trustee_address}"
EOF

blob=$(confidential-data-hub -c /etc/confidential-data-hub.toml get-resource --resource-uri "${key_id}")
echo "blob: $blob"
echo "$blob" | base64 -d > "$resource_path"

sleep 100000000