ARG BASE_IMAGE=mcr.microsoft.com/devcontainers/base:debian-12
FROM ${BASE_IMAGE} AS build

RUN set -eux; \
    rm -f /etc/apt/sources.list.d/debian.sources; \
    printf '%s\n' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/debian bookworm main contrib non-free non-free-firmware' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware' \
        > /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libc6-dev \
    libncurses-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY src/snake_server.c /build/snake_server.c

RUN gcc snake_server.c -o pwn \
    -fno-stack-protector \
    -no-pie \
    -z execstack \
    -fcf-protection=full \
    -lncursesw \
    -ltinfo

FROM ${BASE_IMAGE}

RUN set -eux; \
    rm -f /etc/apt/sources.list.d/debian.sources; \
    printf '%s\n' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/debian bookworm main contrib non-free non-free-firmware' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware' \
        > /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    socat \
    libncursesw6 \
    libtinfo6 \
    ncurses-base \
    ncurses-term \
    libstdc++6 \
    libgcc-s1 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV TERM=xterm

RUN groupadd -r ctf && useradd -r -g ctf ctf && \
    mkdir -p /home/ctf && \
    chown -R ctf:ctf /home/ctf

COPY src/start.sh /start.sh
COPY src/challenge-entry.sh /usr/local/bin/challenge-entry
RUN sed -i 's/\r$//' /start.sh /usr/local/bin/challenge-entry && chmod +x /start.sh /usr/local/bin/challenge-entry

WORKDIR /home/ctf

COPY --from=build /build/pwn /home/ctf/pwn
RUN chmod +x /home/ctf/pwn

RUN set -eux; \
    mkdir -p /home/ctf/lib /home/ctf/lib64 /home/ctf/usr/lib; \
    ldd /home/ctf/pwn | awk '{ \
        if ($1 ~ /^\//) print $1; \
        if ($3 ~ /^\//) print $3; \
    }' | sort -u | while read -r so; do \
        cp -v --parents "$so" /home/ctf/; \
    done; \
    if [ -f /lib64/ld-linux-x86-64.so.2 ]; then \
        cp -v --parents /lib64/ld-linux-x86-64.so.2 /home/ctf/; \
    fi; \
    if [ -f /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 ]; then \
        cp -v --parents /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /home/ctf/; \
    fi; \
    if [ -f /lib/x86_64-linux-gnu/libdl.so.2 ]; then \
        cp -v --parents /lib/x86_64-linux-gnu/libdl.so.2 /home/ctf/; \
    fi; \
    if [ -f /usr/lib/x86_64-linux-gnu/libdl.so.2 ]; then \
        cp -v --parents /usr/lib/x86_64-linux-gnu/libdl.so.2 /home/ctf/; \
    fi; \
    if [ -f /lib/x86_64-linux-gnu/libncursesw.so.6 ]; then \
        cp -v --parents /lib/x86_64-linux-gnu/libncursesw.so.6 /home/ctf/; \
    fi; \
    if [ -f /usr/lib/x86_64-linux-gnu/libncursesw.so.6 ]; then \
        cp -v --parents /usr/lib/x86_64-linux-gnu/libncursesw.so.6 /home/ctf/; \
    fi; \
    if [ -f /lib/x86_64-linux-gnu/libtinfo.so.6 ]; then \
        cp -v --parents /lib/x86_64-linux-gnu/libtinfo.so.6 /home/ctf/; \
    fi; \
    if [ -f /usr/lib/x86_64-linux-gnu/libtinfo.so.6 ]; then \
        cp -v --parents /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /home/ctf/; \
    fi

RUN set -eux; \
    if [ -d /etc/terminfo ]; then \
        cp -a --parents /etc/terminfo /home/ctf/; \
    fi; \
    if [ -d /lib/terminfo ]; then \
        cp -a --parents /lib/terminfo /home/ctf/; \
    fi; \
    if [ -d /usr/share/terminfo ]; then \
        cp -a --parents /usr/share/terminfo /home/ctf/; \
    fi

RUN mkdir -p /home/ctf/bin && \
    cp /bin/sh /home/ctf/bin/ && \
    cp /bin/cat /home/ctf/bin/ && \
    cp /bin/ls /home/ctf/bin/ && \
    chmod +x /home/ctf/bin/*

RUN set -eux; \
    for helper in /bin/sh /bin/cat /bin/ls; do \
        ldd "$helper" | awk '{ \
            if ($1 ~ /^\//) print $1; \
            if ($3 ~ /^\//) print $3; \
        }' | sort -u | while read -r so; do \
            cp -v --parents "$so" /home/ctf/; \
        done; \
    done

RUN set -eux; \
    mkdir -p /home/ctf/dev; \
    mknod -m 666 /home/ctf/dev/null c 1 3; \
    mknod -m 666 /home/ctf/dev/zero c 1 5; \
    mknod -m 666 /home/ctf/dev/random c 1 8; \
    mknod -m 666 /home/ctf/dev/urandom c 1 9

EXPOSE 8000

ENTRYPOINT ["/start.sh"]
