ARG BASE_IMAGE=mcr.microsoft.com/mirror/docker/library/debian:12-slim
FROM ${BASE_IMAGE} AS builder

RUN printf '%s\n' \
    'deb http://mirrors.tuna.tsinghua.edu.cn/debian bookworm main contrib non-free non-free-firmware' \
    'deb http://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware' \
    > /etc/apt/sources.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    busybox-static \
    socat \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

COPY src/start.sh /work/start.sh
COPY src/challenge-entry.sh /work/challenge-entry
COPY src/pwn /work/pwn

RUN set -eux; \
    sed -i 's/\r$//' /work/start.sh /work/challenge-entry; \
    chmod 0755 /work/start.sh /work/challenge-entry /work/pwn; \
    mkdir -p /rootfs/bin /rootfs/usr/bin /rootfs/usr/sbin; \
    cp /bin/busybox /rootfs/bin/busybox; \
    for app in sh cat ls chown chmod; do \
        ln -s /bin/busybox "/rootfs/bin/$app"; \
    done; \
    cp /work/start.sh /rootfs/start.sh; \
    cp /work/challenge-entry /rootfs/usr/bin/challenge-entry; \
    cp /usr/bin/socat /rootfs/usr/bin/socat; \
    cp /usr/sbin/chroot /rootfs/usr/sbin/chroot; \
    for bin in /usr/bin/socat /usr/sbin/chroot /work/pwn; do \
        for lib in $(ldd "$bin" | awk '{ if ($1 ~ /^\//) print $1; if ($3 ~ /^\//) print $3; }' | sort -u); do \
            mkdir -p "/rootfs$(dirname "$lib")"; \
            cp "$lib" "/rootfs$lib"; \
        done; \
    done; \
    mkdir -p /rootfs/home/ctf/lib/x86_64-linux-gnu /rootfs/home/ctf/lib64 /rootfs/home/ctf/bin; \
    cp /work/pwn /rootfs/home/ctf/pwn; \
    cp /bin/busybox /rootfs/home/ctf/bin/busybox; \
    ln -s /bin/busybox /rootfs/home/ctf/bin/sh; \
    ln -s /bin/busybox /rootfs/home/ctf/bin/cat; \
    ln -s /bin/busybox /rootfs/home/ctf/bin/ls; \
    for lib in $(ldd /work/pwn | awk '{ if ($1 ~ /^\//) print $1; if ($3 ~ /^\//) print $3; }' | sort -u); do \
        mkdir -p "/rootfs/home/ctf$(dirname "$lib")"; \
        cp "$lib" "/rootfs/home/ctf$lib"; \
    done; \
    chmod 0755 /rootfs/home/ctf/pwn

FROM scratch

COPY --from=builder /rootfs/ /

EXPOSE 8000

CMD ["/start.sh"]
