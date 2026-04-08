FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=8000

RUN apt-get -o Acquire::Retries=5 update && \
    apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
        ca-certificates \
        socat && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -g 1000 ctf && \
    useradd -u 1000 -g ctf -d /home/ctf -s /bin/sh ctf

WORKDIR /home/ctf

COPY src/pwn /home/ctf/pwn
COPY src/start.sh /start.sh
COPY src/challenge-entry.sh /usr/local/bin/challenge-entry

RUN set -eu; \
    chmod 0755 /home/ctf/pwn /start.sh /usr/local/bin/challenge-entry; \
    mkdir -p /home/ctf/bin /home/ctf/lib/x86_64-linux-gnu /home/ctf/lib64; \
    cp /lib/x86_64-linux-gnu/libc.so.6 /home/ctf/lib/x86_64-linux-gnu/libc.so.6; \
    cp /lib64/ld-linux-x86-64.so.2 /home/ctf/lib64/ld-linux-x86-64.so.2; \
    cp /bin/sh /home/ctf/bin/sh; \
    cp /bin/cat /home/ctf/bin/cat; \
    cp /bin/ls /home/ctf/bin/ls; \
    for lib in $(ldd /bin/sh /bin/cat /bin/ls | grep -o '/lib[^[:space:]]*' | sort -u); do \
        mkdir -p "/home/ctf$(dirname "$lib")"; \
        cp "$lib" "/home/ctf$lib"; \
    done; \
    chown -R root:root /home/ctf; \
    chmod 0755 /home/ctf /home/ctf/bin /home/ctf/lib /home/ctf/lib64 /home/ctf/lib/x86_64-linux-gnu

EXPOSE 8000

CMD ["/start.sh"]
