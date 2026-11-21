# syntax=docker/dockerfile:1.4
FROM --platform=$TARGETOS/$TARGETARCH ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN useradd -m -d /home/container -s /bin/bash container

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gh \
        git \
        iproute2 \
        jq \
        libicu-dev \
        libkrb5-3 \
        openssl \
        ripgrep \
        tini \
        unzip \
        xz-utils \
        zlib1g \
        zstd \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/container

STOPSIGNAL SIGINT

COPY --chmod=755 --chown=root:root ./entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
