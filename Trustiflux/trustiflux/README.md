# Trustiflux

Here are the guide to use secure AI.

## Model Encryption & Update

TODO

## Mount Encrypted Model

TODO

## Launch AI Inference Server

First, you need to mount the encrypted model to `/tmp/encrypted-model`. Then run

```shell
mkdir -p /tmp/plaintext-model
mkdir -p /tmp/encrypted-model
./gen-compose.sh <trustee-url> <decryption-key-id>
# Example:
# ./gen-compose.sh \
#    http://alb-g1hpfiq3zjy42hkmhw.cn-hangzhou.alb.aliyuncs.com/trustee \
#    kbs:///default/apsara-cc-cai/model-decryption-key
docker compose up -d
```

Then, the plaintext model can be found under `/tmp/plaintext-model`. You can use it to launch your own AI inference server.