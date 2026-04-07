ARG BASE_IMAGE=ubuntu:20.04
FROM ${BASE_IMAGE}

ARG KERNEL_URL=https://people.debian.org/~aurel32/qemu/mips/vmlinux-2.6.32-5-4kc-malta
ARG DISK_URL=https://people.debian.org/~aurel32/qemu/mips/debian_squeeze_mips_standard.qcow2

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /opt/hg532-ctf

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        coreutils \
        curl \
        e2fsprogs \
        net-tools \
        procps \
        python3 \
        python3-requests \
        qemu-system-mips \
        tmux \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "$KERNEL_URL" -o vmlinux-2.6.32-5-4kc-malta \
    && curl -fsSL "$DISK_URL" -o debian_squeeze_mips_standard.qcow2

COPY build_router_rootfs_image.sh boot_router.sh init_router_console.sh start.sh exp.py ./
COPY docker-entrypoint.sh ./
COPY ctf ./ctf
COPY _HG532eV100R001C01B020_upgrade_packet.bin.extracted ./_HG532eV100R001C01B020_upgrade_packet.bin.extracted

RUN chmod +x \
    build_router_rootfs_image.sh \
    boot_router.sh \
    init_router_console.sh \
    start.sh \
    docker-entrypoint.sh \
    ctf/install_guest_assets.sh \
    ctf/guest/check_cache.sh

EXPOSE 37215 2222 31337
HEALTHCHECK --interval=20s --timeout=5s --start-period=60s --retries=3 CMD curl -sS -o /dev/null http://127.0.0.1:37215/ctrlt/DeviceUpgrade_1 || exit 1

ENTRYPOINT ["/opt/hg532-ctf/docker-entrypoint.sh"]
