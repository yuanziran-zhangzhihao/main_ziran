#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_DIR="${SESSION_DIR:-/tmp/hg532-session}"
QEMU_PID_FILE="${QEMU_PID_FILE:-$SESSION_DIR/qemu.pid}"

cleanup() {
    local pid=""
    if [[ -f "$QEMU_PID_FILE" ]]; then
        pid="$(tr -d '\r\n' < "$QEMU_PID_FILE")"
    fi
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    fi
    rm -rf "$SESSION_DIR" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

"$SCRIPT_DIR/ctf/install_guest_assets.sh"
RESTART_QEMU=1 SESSION_DIR="$SESSION_DIR" "$SCRIPT_DIR/boot_router.sh"

echo "[*] container ready"
echo "[*] service:   0.0.0.0:37215"
echo "[*] ssh(debug): container:2222 (not exposed by default)"
echo "[*] checker:   /bin/check_cache.sh"
echo "[*] cachefile: /tmp/ctf.cache"
echo "[*] console:   $SESSION_DIR/console.log"

tail -f /dev/null &
wait $!
