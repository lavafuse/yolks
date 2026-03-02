# ----------------------------------
# Environment: Postgres DB
# ----------------------------------
FROM    --platform=$TARGETOS/$TARGETARCH postgres:18-alpine

LABEL   author="Lavafuse" maintainer="contact@lavafuse.net"

RUN     adduser -D -h /home/container container

RUN     apk add --no-cache curl iproute2 ca-certificates fontconfig git openssl sqlite tar tzdata

USER    container
ENV     USER=container HOME=/home/container
WORKDIR /home/container


COPY    ./entrypoint.sh /entrypoint.sh
CMD     ["/entrypoint.sh"]