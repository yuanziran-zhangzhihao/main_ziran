FROM debian:bookworm-slim

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
RUN chmod +x /start.sh

WORKDIR /home/ctf

COPY src/pwn /home/ctf/pwn
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
    if [ -f /lib/x86_64-linux-gnu/libncurses.so.6 ]; then \
        cp -v --parents /lib/x86_64-linux-gnu/libncurses.so.6 /home/ctf/; \
    fi; \
    if [ -f /usr/lib/x86_64-linux-gnu/libncurses.so.6 ]; then \
        cp -v --parents /usr/lib/x86_64-linux-gnu/libncurses.so.6 /home/ctf/; \
    fi; \
    if [ -f /lib/x86_64-linux-gnu/libtinfo.so.6 ]; then \
        cp -v --parents /lib/x86_64-linux-gnu/libtinfo.so.6 /home/ctf/; \
    fi; \
    if [ -f /usr/lib/x86_64-linux-gnu/libtinfo.so.6 ]; then \
        cp -v --parents /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /home/ctf/; \
    fi

RUN mkdir -p /home/ctf/bin && \
    cp /bin/sh /home/ctf/bin/ && \
    cp /bin/cat /home/ctf/bin/ && \
    cp /bin/ls /home/ctf/bin/ && \
    chmod +x /home/ctf/bin/*

RUN set -eux; \
    mkdir -p /home/ctf/dev; \
    mknod -m 666 /home/ctf/dev/null c 1 3; \
    mknod -m 666 /home/ctf/dev/zero c 1 5; \
    mknod -m 666 /home/ctf/dev/random c 1 8; \
    mknod -m 666 /home/ctf/dev/urandom c 1 9

EXPOSE 8000

CMD ["/start.sh"]
