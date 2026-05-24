ARG BASE_IMAGE=mcr.microsoft.com/devcontainers/base:ubuntu-22.04
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    printf '%s\n' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe' \
        > /etc/apt/sources.list

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        coreutils \
        file \
        gcc \
        make \
        python3 \
        tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
COPY . /work
COPY docker/build.sh /usr/local/bin/export-dist
COPY docker/session.sh /usr/local/bin/challenge-session
COPY docker/start.sh /usr/local/bin/challenge-start
COPY docker/server.py /usr/local/bin/challenge-server
RUN sed -i 's/\r$//' /usr/local/bin/export-dist /usr/local/bin/challenge-session /usr/local/bin/challenge-start \
    && chmod 0755 /usr/local/bin/export-dist /usr/local/bin/challenge-session /usr/local/bin/challenge-start /usr/local/bin/challenge-server \
    && cd /work/quickjs-2024-01-13 \
    && make clean >/dev/null 2>&1 || true \
    && make qjs

EXPOSE 9999
ENTRYPOINT ["/usr/local/bin/challenge-start"]
