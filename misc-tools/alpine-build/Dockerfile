FROM alpine:latest

RUN apk add --no-cache \
    alpine-sdk \
    abuild \
    bash \
    git \
    docker-cli \
    sudo

RUN adduser -D -G abuild builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER builder
WORKDIR /home/builder

CMD ["/bin/sh"]
