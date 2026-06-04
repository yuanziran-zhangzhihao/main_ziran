ARG BASE_IMAGE=mcr.microsoft.com/mirror/docker/library/ubuntu:20.04
FROM ${BASE_IMAGE} AS builder

RUN sed -i \
        -e 's|http://archive.ubuntu.com/ubuntu/|http://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' \
        -e 's|http://security.ubuntu.com/ubuntu/|http://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' \
        -e '/^[[:space:]]*deb .* focal-backports /d' \
        -e '/^[[:space:]]*deb .* multiverse/d' \
        /etc/apt/sources.list && \
    apt-get update -o Acquire::Retries=5 && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        busybox-static \
        socat \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /work

COPY src/pwn /work/pwn
COPY src/start.sh /work/start.sh

RUN set -eux; \
    sed -i 's/\r$//' /work/start.sh; \
    chmod 0755 /work/pwn /work/start.sh; \
    mkdir -p /rootfs/bin /rootfs/usr/bin /rootfs/usr/sbin; \
    cp /bin/busybox /rootfs/bin/busybox; \
    for app in sh grep sleep chown chmod; do \
        ln -s /bin/busybox "/rootfs/bin/$app"; \
    done; \
    cp /work/start.sh /rootfs/start.sh; \
    cp /usr/bin/socat /rootfs/usr/bin/socat; \
    cp /usr/sbin/chroot /rootfs/usr/sbin/chroot; \
    for bin in /usr/bin/socat /usr/sbin/chroot; do \
        for lib in $(ldd "$bin" | awk '{ if ($1 ~ /^\//) print $1; if ($3 ~ /^\//) print $3; }' | sort -u); do \
            mkdir -p "/rootfs$(dirname "$lib")"; \
            cp "$lib" "/rootfs$lib"; \
        done; \
    done; \
    mkdir -p /rootfs/home/ctf/bin /rootfs/home/ctf/lib/x86_64-linux-gnu /rootfs/home/ctf/lib64; \
    cp /work/pwn /rootfs/home/ctf/pwn; \
    cp /bin/busybox /rootfs/home/ctf/bin/busybox; \
    ln -s /bin/busybox /rootfs/home/ctf/bin/sh; \
    ln -s /bin/busybox /rootfs/home/ctf/bin/cat; \
    ln -s /bin/busybox /rootfs/home/ctf/bin/ls; \
    cp /lib/x86_64-linux-gnu/libc.so.6 /rootfs/home/ctf/libc.so.6; \
    cp /lib64/ld-linux-x86-64.so.2 /rootfs/home/ctf/ld-linux-x86-64.so.2; \
    cp /lib/x86_64-linux-gnu/libc.so.6 /rootfs/home/ctf/lib/x86_64-linux-gnu/libc.so.6; \
    cp /lib64/ld-linux-x86-64.so.2 /rootfs/home/ctf/lib64/ld-linux-x86-64.so.2

FROM scratch

COPY --from=builder /rootfs/ /

EXPOSE 8000

CMD ["/start.sh"]
