FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    socat \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r ctf && useradd -r -g ctf ctf && \
    mkdir -p /home/ctf && \
    chown ctf:ctf /home/ctf

COPY src/start.sh /start.sh
COPY src/challenge-entry.sh /usr/local/bin/challenge-entry
RUN chmod +x /start.sh /usr/local/bin/challenge-entry

WORKDIR /home/ctf

COPY src/pwn /home/ctf/pwn
RUN chmod +x /home/ctf/pwn

RUN set -eux; \
    mkdir -p /home/ctf/lib/x86_64-linux-gnu /home/ctf/lib64 /home/ctf/bin; \
    cp /bin/sh /home/ctf/bin/sh; \
    cp /bin/cat /home/ctf/bin/cat; \
    cp /bin/ls /home/ctf/bin/ls; \
    chmod 0755 /home/ctf/bin/sh /home/ctf/bin/cat /home/ctf/bin/ls; \
    for lib in $(ldd /home/ctf/pwn /bin/sh /bin/cat /bin/ls | awk '{ if ($1 ~ /^\\//) print $1; if ($3 ~ /^\\//) print $3; }' | sort -u); do \
        mkdir -p "/home/ctf$(dirname "$lib")"; \
        cp "$lib" "/home/ctf$lib"; \
    done

EXPOSE 8000

CMD ["/start.sh"]
