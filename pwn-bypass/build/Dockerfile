FROM debian:bookworm-slim

RUN apt-get update -o Acquire::Retries=3 && apt-get install -y -o Acquire::Retries=3 --no-install-recommends \
    socat \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r ctf && useradd -r -g ctf ctf && \
    mkdir -p /home/ctf && \
    chown -R ctf:ctf /home/ctf

COPY src/start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh && chmod +x /start.sh

WORKDIR /home/ctf
COPY src/pwn /home/ctf/pwn

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
