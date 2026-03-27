FROM ubuntu:16.04

# Keep only the repositories needed for runtime packages and avoid flaky backports.
RUN sed -i '/xenial-backports/d' /etc/apt/sources.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        socat \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r ctf && \
    useradd -r -g ctf -d /home/ctf -s /bin/sh ctf

WORKDIR /home/ctf

COPY src/pwn /home/ctf/pwn
COPY src/start.sh /start.sh

# The binary is patched to use:
# - interpreter: ./ld-linux-x86-64.so.2
# - NEEDED:      ./libc.so.6
# so both files must exist at the root of the chroot.
RUN chmod 0755 /home/ctf/pwn /start.sh && \
    mkdir -p /home/ctf/bin /home/ctf/lib/x86_64-linux-gnu /home/ctf/lib64 && \
    cp /lib/x86_64-linux-gnu/libc.so.6 /home/ctf/libc.so.6 && \
    cp /lib64/ld-linux-x86-64.so.2 /home/ctf/ld-linux-x86-64.so.2 && \
    cp /lib/x86_64-linux-gnu/libc.so.6 /home/ctf/lib/x86_64-linux-gnu/libc.so.6 && \
    cp /lib64/ld-linux-x86-64.so.2 /home/ctf/lib64/ld-linux-x86-64.so.2 && \
    cp /bin/sh /home/ctf/bin/sh && \
    cp /bin/cat /home/ctf/bin/cat && \
    cp /bin/ls /home/ctf/bin/ls && \
    for lib in $(ldd /bin/sh /bin/cat /bin/ls | grep -o '/lib[^[:space:]]*' | sort -u); do \
        mkdir -p "/home/ctf$(dirname "$lib")"; \
        cp "$lib" "/home/ctf$lib"; \
    done && \
    chown -R root:root /home/ctf && \
    chmod 0755 /home/ctf /home/ctf/bin /home/ctf/lib /home/ctf/lib64 /home/ctf/lib/x86_64-linux-gnu

EXPOSE 8000

CMD ["/start.sh"]
