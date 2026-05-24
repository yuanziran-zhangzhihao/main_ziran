ARG BASE_IMAGE=mcr.microsoft.com/devcontainers/base:debian-12
FROM ${BASE_IMAGE} AS builder

RUN set -eux; \
    rm -f /etc/apt/sources.list.d/debian.sources; \
    printf '%s\n' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/debian bookworm main contrib non-free non-free-firmware' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware' \
        > /etc/apt/sources.list

RUN apt-get update -o Acquire::Retries=3 && apt-get install -y -o Acquire::Retries=3 --no-install-recommends \
    gcc \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY src/bypass.c /src/bypass.c

RUN gcc -O0 -fno-stack-protector -no-pie -z norelro -fcf-protection=full -Wl,-z,ibt,-z,shstk \
    -o /src/pwn /src/bypass.c

FROM ${BASE_IMAGE}

RUN set -eux; \
    rm -f /etc/apt/sources.list.d/debian.sources; \
    printf '%s\n' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/debian bookworm main contrib non-free non-free-firmware' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware' \
        > /etc/apt/sources.list

RUN apt-get update -o Acquire::Retries=3 && apt-get install -y -o Acquire::Retries=3 --no-install-recommends \
    socat \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r ctf && useradd -r -g ctf ctf && \
    mkdir -p /home/ctf && \
    chown -R ctf:ctf /home/ctf

COPY src/start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

WORKDIR /home/ctf
COPY --from=builder /src/pwn /home/ctf/pwn

RUN set -eux; \
    chmod +x /home/ctf/pwn; \
    cp -v --parents /bin/sh /bin/cat /bin/ls /home/ctf/; \
    { \
        ldd /home/ctf/pwn; \
        ldd /bin/sh; \
        ldd /bin/cat; \
        ldd /bin/ls; \
    } | awk '{ \
        if ($1 ~ /^\//) print $1; \
        if ($3 ~ /^\//) print $3; \
    }' | sort -u | while read -r so; do \
        cp -v --parents "$so" /home/ctf/; \
    done; \
    /usr/sbin/chroot /home/ctf /lib64/ld-linux-x86-64.so.2 --list /pwn >/dev/null; \
    /usr/sbin/chroot /home/ctf /bin/cat /bin/sh >/dev/null; \
    /usr/sbin/chroot /home/ctf /bin/ls / >/dev/null

EXPOSE 8000

CMD ["/start.sh"]
