ARG BASE_IMAGE=mcr.microsoft.com/devcontainers/base:debian-12
FROM ${BASE_IMAGE}

RUN set -eux; \
    rm -f /etc/apt/sources.list.d/debian.sources; \
    printf '%s\n' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/debian bookworm main contrib non-free non-free-firmware' \
        'deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware' \
        > /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    socat \
    libncurses6 \
    libtinfo6 \
    libstdc++6 \
    libgcc-s1 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r ctf && useradd -r -g ctf ctf && \
    mkdir -p /home/ctf && \
    chown -R ctf:ctf /home/ctf

COPY src/start.sh /start.sh
COPY src/challenge-entry.sh /usr/local/bin/challenge-entry
RUN sed -i 's/\r$//' /start.sh /usr/local/bin/challenge-entry && chmod +x /start.sh /usr/local/bin/challenge-entry

WORKDIR /home/ctf

COPY src/pwn /home/ctf/pwn
RUN chmod +x /home/ctf/pwn

RUN set -eux; \
    mkdir -p /home/ctf/lib /home/ctf/lib64; \
    ldd /home/ctf/pwn | awk '{ \
        if ($1 ~ /^\//) print $1; \
        if ($3 ~ /^\//) print $3; \
    }' | sort -u | while read -r so; do \
        # 把 /lib/x86_64-linux-gnu/xxx.so.* 这种路径按原目录结构复制到 /home/ctf/
        cp -v --parents "$so" /home/ctf/; \
    done; \
    if [ -f /lib64/ld-linux-x86-64.so.2 ]; then \
        cp -v --parents /lib64/ld-linux-x86-64.so.2 /home/ctf/; \
    fi; \
    if [ -f /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 ]; then \
        cp -v --parents /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /home/ctf/; \
    fi; \
    if [ -f /lib/terminfo/x/xterm ]; then \
        cp -v --parents /lib/terminfo/x/xterm /home/ctf/; \
    fi; \
    if [ -f /lib/terminfo/x/xterm-256color ]; then \
        cp -v --parents /lib/terminfo/x/xterm-256color /home/ctf/; \
    fi

RUN mkdir -p /home/ctf/bin && \
    cp /bin/sh /home/ctf/bin/ && \
    cp /bin/cat /home/ctf/bin/ && \
    cp /bin/ls /home/ctf/bin/ && \
    chmod +x /home/ctf/bin/*

EXPOSE 8000

CMD ["/start.sh"]
