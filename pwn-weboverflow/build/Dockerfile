ARG BASE_IMAGE=debian:bookworm-slim
FROM ${BASE_IMAGE}

RUN set -eux; \
    missing_packages=""; \
    command -v socat >/dev/null 2>&1 || missing_packages="$missing_packages socat"; \
    command -v chroot >/dev/null 2>&1 || missing_packages="$missing_packages coreutils"; \
    command -v groupadd >/dev/null 2>&1 || missing_packages="$missing_packages passwd"; \
    command -v useradd >/dev/null 2>&1 || missing_packages="$missing_packages passwd"; \
    if [ -n "$missing_packages" ]; then \
      if ! command -v apt-get >/dev/null 2>&1; then \
        echo "base image must provide apt-get, or preinstall socat/chroot/useradd" >&2; \
        exit 1; \
      fi; \
      apt-get update; \
      apt-get install -y --no-install-recommends ca-certificates $missing_packages; \
      rm -rf /var/lib/apt/lists/*; \
    fi

RUN set -eux; \
    if ! getent group ctf >/dev/null 2>&1; then \
      groupadd -r ctf; \
    fi; \
    if ! id -u ctf >/dev/null 2>&1; then \
      useradd -r -g ctf -d /home/ctf -M ctf; \
    fi; \
    mkdir -p /home/ctf; \
    chown ctf:ctf /home/ctf

COPY src/start.sh /start.sh
RUN chmod 0755 /start.sh

WORKDIR /home/ctf

COPY src/pwn /home/ctf/pwn
COPY src/server /home/ctf/server
RUN chmod 0755 /home/ctf/pwn /home/ctf/server

RUN set -eux; \
    mkdir -p /home/ctf/bin /home/ctf/tmp; \
    cp /bin/sh /home/ctf/bin/sh; \
    chmod 0755 /home/ctf/bin/sh; \
    chmod 1777 /home/ctf/tmp; \
    for bin in /home/ctf/pwn /home/ctf/server /bin/sh; do \
      if ldd "$bin" >/dev/null 2>&1; then \
        ldd "$bin" \
          | awk '($3 ~ /^\//){print $3} ($1 ~ /^\//){print $1}' \
          | sort -u \
          | xargs -r -I{} cp -v --parents {} /home/ctf; \
      fi; \
    done; \
    if [ -f /lib64/ld-linux-x86-64.so.2 ]; then \
      cp -v --parents /lib64/ld-linux-x86-64.so.2 /home/ctf; \
    fi; \
    for preload in /usr/libexec/coreutils/libstdbuf.so /usr/lib/coreutils/libstdbuf.so; do \
      if [ -f "$preload" ]; then \
        cp -v --parents "$preload" /home/ctf; \
        ldd "$preload" \
          | awk '($3 ~ /^\//){print $3} ($1 ~ /^\//){print $1}' \
          | sort -u \
          | xargs -r -I{} cp -v --parents {} /home/ctf; \
      fi; \
    done

EXPOSE 8000

CMD ["/start.sh"]
