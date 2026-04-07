#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_DIR="${SESSION_DIR:-/tmp/hg532-session}"
QEMU_PID_FILE="${QEMU_PID_FILE:-$SESSION_DIR/qemu.pid}"
PUBLIC_PORT="${PUBLIC_PORT:-37215}"
INTERNAL_UPNP_PORT="${INTERNAL_UPNP_PORT:-37216}"
FLAG_CALLBACK_PORT="${FLAG_CALLBACK_PORT:-39000}"
RELAY_PID=""

cleanup() {
    local pid=""
    if [[ -n "${RELAY_PID:-}" ]] && kill -0 "$RELAY_PID" 2>/dev/null; then
        kill "$RELAY_PID" 2>/dev/null || true
        wait "$RELAY_PID" 2>/dev/null || true
    fi
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
python3 "$SCRIPT_DIR/host_relay.py" \
    --listen-port "$PUBLIC_PORT" \
    --target-port "$INTERNAL_UPNP_PORT" \
    --callback-port "$FLAG_CALLBACK_PORT" &
RELAY_PID="$!"

RESTART_QEMU=1 \
SESSION_DIR="$SESSION_DIR" \
UPNP_FWD_PORT="$INTERNAL_UPNP_PORT" \
"$SCRIPT_DIR/boot_router.sh"

echo "[*] container ready"
echo "[*] service:   0.0.0.0:${PUBLIC_PORT}"
echo "[*] guestupnp: 127.0.0.1:${INTERNAL_UPNP_PORT} -> guest:37215"
echo "[*] callback:  10.0.2.2:${FLAG_CALLBACK_PORT}"
echo "[*] ssh(debug): container:2222 (not exposed by default)"
echo "[*] checker:   /bin/check_cache.sh"
echo "[*] cachefile: /tmp/ctf.cache"
echo "[*] console:   $SESSION_DIR/console.log"

tail -f /dev/null &
wait $!
