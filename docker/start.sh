#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-9999}"

if [[ -z "${FLAG_VALUE:-}" ]]; then
    rand="$(tr -dc 'a-z0-9' </dev/urandom | head -c 24 || true)"
    FLAG_VALUE="FLAG{${rand:-quickjs_uaf_local}}"
fi
export FLAG_VALUE

echo "[*] quickjs-uaf-baby listening on 0.0.0.0:${PORT}"
echo "[*] runtime flag: ${FLAG_VALUE}"
echo "[*] send a JavaScript file, then stop sending data"

exec python3 /usr/local/bin/challenge-server
