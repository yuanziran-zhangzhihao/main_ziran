#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/opt/core_level0"
WORK_DIR="/tmp/core_level0-runtime"
BASE_INITRD="$BASE_DIR/base/rootfs.cpio.gz"
RUNTIME_ROOT="$WORK_DIR/rootfs"
RUNTIME_INITRD="$WORK_DIR/rootfs.runtime.cpio.gz"
PORT="${PORT:-1337}"

pick_flag() {
    local name value

    for name in A1CTF_FLAG PCTF_FLAG GZCTF_FLAG FLAG FLAG_VALUE; do
        value="${!name:-}"
        if [ -n "$value" ]; then
            printf '%s' "$value"
            return 0
        fi
    done

    printf 'FLAG{%s}' "$(od -An -tx1 -N8 /dev/urandom | tr -d ' \n')"
}

FLAG_CONTENT="$(pick_flag)"

rm -rf "$WORK_DIR"
mkdir -p "$RUNTIME_ROOT"

(
    cd "$RUNTIME_ROOT"
    gzip -dc "$BASE_INITRD" | cpio -id --quiet
)

mkdir -p "$RUNTIME_ROOT/etc"
chmod 0755 "$RUNTIME_ROOT/etc"
printf '%s' "$FLAG_CONTENT" > "$RUNTIME_ROOT/etc/challenge.flag"
chmod 0600 "$RUNTIME_ROOT/etc/challenge.flag"

(
    cd "$RUNTIME_ROOT"
    find . -print0 | cpio --null -o --format=newc | gzip -9
) > "$RUNTIME_INITRD"

export CORE_LEVEL0_BZIMAGE="$BASE_DIR/base/bzImage"
export CORE_LEVEL0_INITRD="$RUNTIME_INITRD"

echo "[*] core_level0 docker service listening on ${PORT}"
echo "[*] runtime initramfs prepared at ${RUNTIME_INITRD}"

exec socat -T600 TCP-LISTEN:"$PORT",reuseaddr,fork EXEC:"/usr/local/bin/session.sh",pty,rawer,echo=0,stderr,setsid,sigint,sane
