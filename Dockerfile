ARG BASE_IMAGE=mcr.microsoft.com/devcontainers/base:ubuntu-22.04
FROM ${BASE_IMAGE} AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    printf '%s\n' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe' \
        > /etc/apt/sources.list

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bc \
        bison \
        build-essential \
        busybox-static \
        ca-certificates \
        cpio \
        flex \
        gcc \
        gzip \
        kmod \
        libelf-dev \
        linux-headers-generic \
        linux-image-generic \
        make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
COPY Makefile README.md babydriver.c exp.c run.sh ./
COPY initramfs ./initramfs
COPY docker/build.sh /usr/local/bin/challenge-build
RUN sed -i 's/\r$//' /usr/local/bin/challenge-build \
    && chmod 0755 /usr/local/bin/challenge-build \
    && /usr/local/bin/challenge-build

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
        ca-certificates \
        coreutils \
        cpio \
        gzip \
        qemu-system-x86 \
        socat \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/core_level0

COPY --from=builder /work/bzImage /opt/core_level0/base/bzImage
COPY --from=builder /work/rootfs.cpio.gz /opt/core_level0/base/rootfs.cpio.gz
COPY --from=builder /work/attachments/ /opt/core_level0/attachments/
COPY --from=builder /work/selftest/ /opt/core_level0/selftest/
COPY docker/start.sh /usr/local/bin/start.sh
COPY docker/session.sh /usr/local/bin/session.sh
COPY docker/export-artifacts.sh /usr/local/bin/export-artifacts.sh
COPY docker/post-build.sh /usr/local/bin/post-build.sh

RUN sed -i 's/\r$//' \
        /usr/local/bin/start.sh \
        /usr/local/bin/session.sh \
        /usr/local/bin/export-artifacts.sh \
        /usr/local/bin/post-build.sh \
    && chmod 0755 \
        /usr/local/bin/start.sh \
        /usr/local/bin/session.sh \
        /usr/local/bin/export-artifacts.sh \
        /usr/local/bin/post-build.sh

ENV PORT=1337
ENV SESSION_TIMEOUT=300

EXPOSE 1337

CMD ["/usr/local/bin/start.sh"]
