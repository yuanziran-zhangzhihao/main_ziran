#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_FWD_PORT="${SSH_FWD_PORT:-2222}"
UPNP_FWD_PORT="${UPNP_FWD_PORT:-37215}"
GUEST_UPNP_PORT="${GUEST_UPNP_PORT:-37215}"
RESTART_QEMU="${RESTART_QEMU:-1}"
CHECK_TIMEOUT="${CHECK_TIMEOUT:-30}"
SESSION_DIR="${SESSION_DIR:-/tmp/hg532-session}"
CONSOLE_FIFO="${CONSOLE_FIFO:-$SESSION_DIR/console.in}"
CONSOLE_LOG="${CONSOLE_LOG:-$SESSION_DIR/console.log}"
QEMU_PID_FILE="${QEMU_PID_FILE:-$SESSION_DIR/qemu.pid}"

qemu_pid() {
    if [[ -f "$QEMU_PID_FILE" ]]; then
        tr -d '\r\n' < "$QEMU_PID_FILE"
    fi
}

qemu_is_alive() {
    local pid
    pid="$(qemu_pid)"
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

stop_qemu() {
    local pid
    pid="$(qemu_pid)"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        for _ in 1 2 3 4 5; do
            if ! kill -0 "$pid" 2>/dev/null; then
                break
            fi
            sleep 1
        done
        kill -9 "$pid" 2>/dev/null || true
    fi
}

start_qemu() {
    local quoted_dir
    local quoted_fifo
    local quoted_log

    mkdir -p "$SESSION_DIR"
    rm -f "$CONSOLE_FIFO" "$CONSOLE_LOG" "$QEMU_PID_FILE"
    mkfifo "$CONSOLE_FIFO"

    quoted_dir="$(printf '%q' "$SCRIPT_DIR")"
    quoted_fifo="$(printf '%q' "$CONSOLE_FIFO")"
    quoted_log="$(printf '%q' "$CONSOLE_LOG")"

    nohup bash -lc "cd $quoted_dir && exec 3<>$quoted_fifo && exec ./start.sh <&3 >>$quoted_log 2>&1" >/dev/null 2>&1 &

    echo "$!" > "$QEMU_PID_FILE"
}

if [[ -x "$SCRIPT_DIR/ctf/install_guest_assets.sh" ]]; then
    "$SCRIPT_DIR/ctf/install_guest_assets.sh"
fi

"$SCRIPT_DIR/build_router_rootfs_image.sh"

if qemu_is_alive; then
    if [[ "$RESTART_QEMU" == "1" ]]; then
        stop_qemu
    else
        echo "[*] reusing existing qemu session: $SESSION_DIR"
    fi
fi

if ! qemu_is_alive; then
    start_qemu
fi

env \
    SESSION_DIR="$SESSION_DIR" \
    CONSOLE_FIFO="$CONSOLE_FIFO" \
    CONSOLE_LOG="$CONSOLE_LOG" \
    QEMU_PID_FILE="$QEMU_PID_FILE" \
    ROUTER_PORT="$GUEST_UPNP_PORT" \
    SSH_PORT="$SSH_FWD_PORT" \
    "$SCRIPT_DIR/init_router_console.sh"

for ((i = 0; i < CHECK_TIMEOUT; i++)); do
    if timeout 2 bash -lc "exec 3<>/dev/tcp/127.0.0.1/${UPNP_FWD_PORT}; printf 'GET /ctrlt/DeviceUpgrade_1 HTTP/1.0\r\nHost: 127.0.0.1\r\n\r\n' >&3; IFS= read -r line <&3; [[ \$line == HTTP/* ]]" >/dev/null 2>&1; then
        echo "[+] router http endpoint is reachable: 127.0.0.1:${UPNP_FWD_PORT}"
        echo "[*] ssh:  ssh -p ${SSH_FWD_PORT} root@127.0.0.1"
        echo "[*] exp:  python3 exp.py"
        echo "[*] view: tail -f ${CONSOLE_LOG}"
        exit 0
    fi
    sleep 1
done

echo "[-] router http endpoint did not become reachable: 127.0.0.1:${UPNP_FWD_PORT}" >&2
exit 1
