#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_SESSION="${TMUX_SESSION:-hg532}"

cleanup() {
    tmux kill-session -t "$TMUX_SESSION" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

"$SCRIPT_DIR/ctf/install_guest_assets.sh"
RESTART_QEMU=1 TMUX_SESSION="$TMUX_SESSION" "$SCRIPT_DIR/boot_router.sh"

echo "[*] container ready"
echo "[*] service:   0.0.0.0:37215"
echo "[*] ssh(debug): container:2222 (not exposed by default)"
echo "[*] checker:   /bin/check_cache.sh"
echo "[*] cachefile: /tmp/ctf.cache"

tail -f /dev/null &
wait $!
