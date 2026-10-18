# ----------------------------------
# Environment: MariaDB
# ----------------------------------
FROM mariadb:11.8

LABEL author="Lavafuse" maintainer="contact@lavafuse.net"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install -y --no-install-recommends \
  gettext-base \
  libnss-wrapper \
  && rm -rf /var/lib/apt/lists/*

## Prepare NSS Wrapper for the entrypoint
ENV NSS_WRAPPER_PASSWD=/tmp/passwd NSS_WRAPPER_GROUP=/tmp/group
COPY --chown=root:root --chmod=644 nss/passwd.template nss/group.template /

ENV USER=container HOME=/home/container
WORKDIR /home/container

COPY --chown=root:root --chmod=755 ../entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]