# Copyright (c) 2024 by Alibaba.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

ARG BASE_IMAGE=debian:stable-slim

FROM ${BASE_IMAGE}

WORKDIR /usr/src

RUN printf '\
    # 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释\n\
    deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware\n\
    # deb-src http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware\n\
    deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware\n\
    # deb-src http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware\n\
    deb http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware\n\
    # deb-src http://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware\n\
    # 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换\n\
    deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware\n\
    # deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware\n\
    ' > /etc/apt/sources.list

RUN apt update -y && apt install -y curl wget unzip && \
    apt clean all && \
    rm -rf /tmp/*

# install gocryptfs-v2.4
RUN mkdir gocryptfs && cd gocryptfs && \
    wget https://github.com/rfjakob/gocryptfs/releases/download/v2.4.0/gocryptfs_v2.4.0_linux-static_amd64.tar.gz && \
    tar xf gocryptfs_v2.4.0_linux-static_amd64.tar.gz && \
    install -m 0755 ./gocryptfs /usr/local/bin && \
    cd .. && rm -rf gocryptfs

# Copy binaries
COPY gocryptfs-start.sh /usr/bin/start.sh