#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_SESSION="${TMUX_SESSION:-hg532}"
SSH_FWD_PORT="${SSH_FWD_PORT:-2222}"
UPNP_FWD_PORT="${UPNP_FWD_PORT:-37215}"
GUEST_UPNP_PORT="${GUEST_UPNP_PORT:-37215}"
RESTART_QEMU="${RESTART_QEMU:-1}"
CHECK_TIMEOUT="${CHECK_TIMEOUT:-30}"

"$SCRIPT_DIR/build_router_rootfs_image.sh"

if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    if [[ "$RESTART_QEMU" == "1" ]]; then
        tmux kill-session -t "$TMUX_SESSION"
    else
        echo "[*] reusing existing tmux session: $TMUX_SESSION"
    fi
fi

if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    tmux new-session -d -s "$TMUX_SESSION" -c "$SCRIPT_DIR" "env SSH_FWD_PORT=$SSH_FWD_PORT UPNP_FWD_PORT=$UPNP_FWD_PORT GUEST_UPNP_PORT=$GUEST_UPNP_PORT ./start.sh"
fi

env TMUX_SESSION="$TMUX_SESSION" ROUTER_PORT="$GUEST_UPNP_PORT" SSH_PORT="$SSH_FWD_PORT" "$SCRIPT_DIR/init_router_console.sh"

for ((i = 0; i < CHECK_TIMEOUT; i++)); do
    if timeout 2 bash -lc "exec 3<>/dev/tcp/127.0.0.1/${UPNP_FWD_PORT}; printf 'GET /ctrlt/DeviceUpgrade_1 HTTP/1.0\r\nHost: 127.0.0.1\r\n\r\n' >&3; IFS= read -r line <&3; [[ \$line == HTTP/* ]]" >/dev/null 2>&1; then
        echo "[+] router http endpoint is reachable: 127.0.0.1:${UPNP_FWD_PORT}"
        echo "[*] ssh:  ssh -p ${SSH_FWD_PORT} root@127.0.0.1"
        echo "[*] exp:  python3 exp.py"
        echo "[*] view: tmux attach -t ${TMUX_SESSION}"
        exit 0
    fi
    sleep 1
done

echo "[-] router http endpoint did not become reachable: 127.0.0.1:${UPNP_FWD_PORT}" >&2
exit 1
