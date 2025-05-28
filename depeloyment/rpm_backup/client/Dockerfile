# Copyright (c) 2024 by Alibaba.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

ARG BASE_IMAGE=registry.openanolis.cn/openanolis/anolisos:23.2

FROM ${BASE_IMAGE} AS trustee-client-builder

RUN yum install -y perl wget curl clang openssh-clients openssl-devel protobuf-devel git

WORKDIR /usr/src

RUN git clone --branch v1.1.1 https://github.com/openanolis/trustee.git

WORKDIR /usr/src/trustee

# Install Rust
RUN export RUSTUP_DIST_SERVER='https://mirrors.ustc.edu.cn/rust-static' && \
    export RUSTUP_UPDATE_ROOT='https://mirrors.ustc.edu.cn/rust-static/rustup' && \
    curl --proto '=https' --tlsv1.2 -sSf https://mirrors.aliyun.com/repo/rust/rustup-init.sh | \
    sh  -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN export RUSTUP_DIST_SERVER='https://mirrors.ustc.edu.cn/rust-static' && \
    export RUSTUP_UPDATE_ROOT='https://mirrors.ustc.edu.cn/rust-static/rustup' && \
    rustup toolchain install 1.79.0-x86_64-unknown-linux-gnu
RUN printf '[source.crates-io]\nreplace-with = "aliyun"\n\n[source.aliyun]\nregistry = "sparse+https://mirrors.aliyun.com/crates.io-index/"\n' \
    > ~/.cargo/config.toml

# Build trustee-client
RUN cargo build -p kbs-client --locked --release --no-default-features --features sample_only


FROM ${BASE_IMAGE}

WORKDIR /tmp

RUN yum install -y anolis-epao-release && \
    yum install -y trustee trusted-network-gateway && \
    yum install -y wget nc && \
    # yum install -y gocryptfs && \
    yum clean all && \
    rm -rf /var/cache/yum

# install yq
RUN wget https://github.com/mikefarah/yq/releases/download/v4.45.4/yq_linux_amd64 -O /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

# install gocryptfs-v2.4
RUN mkdir gocryptfs && cd gocryptfs && \
    wget https://github.com/rfjakob/gocryptfs/releases/download/v2.4.0/gocryptfs_v2.4.0_linux-static_amd64.tar.gz && \
    tar xf gocryptfs_v2.4.0_linux-static_amd64.tar.gz && \
    install -m 0755 ./gocryptfs /usr/local/bin && \
    cd .. && rm -rf gocryptfs

COPY --from=trustee-client-builder /usr/src/trustee/target/release/kbs-client /usr/local/bin/trustee-client

CMD ["restful-as", "--socket", "0.0.0.0:8080", "--config-file", "/etc/config.json"]