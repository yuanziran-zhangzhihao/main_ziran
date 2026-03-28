#!/bin/sh
set -eu

if [ "${A1CTF_FLAG:-}" ]; then
    INSERT_FLAG="$A1CTF_FLAG"
    unset A1CTF_FLAG
elif [ "${PCTF_FLAG:-}" ]; then
    INSERT_FLAG="$PCTF_FLAG"
    unset PCTF_FLAG
elif [ "${GZCTF_FLAG:-}" ]; then
    INSERT_FLAG="$GZCTF_FLAG"
    unset GZCTF_FLAG
elif [ "${FLAG:-}" ]; then
    INSERT_FLAG="$FLAG"
    unset FLAG
else
    INSERT_FLAG="PCTF{!!!!_FLAG_ERROR_ASK_ADMIN_!!!!}"
fi

printf '%s' "$INSERT_FLAG" > /home/ctf/flag
unset INSERT_FLAG
chown ctf:ctf /home/ctf/flag

cp /bin/sh /home/ctf/sh
chmod +x /home/ctf/sh

CHROOT_BIN="/usr/sbin/chroot"
if [ ! -x "$CHROOT_BIN" ]; then
  CHROOT_BIN="/usr/bin/chroot"
fi

SERVER_ENABLE="${SERVER_ENABLE:-1}"
SERVER_MODE="${SERVER_MODE:-daemon}"
SERVER_PORT="${SERVER_PORT:-8001}"
SERVER_INNER_PORT="${SERVER_INNER_PORT:-8080}"
SERVER_CMD="${SERVER_CMD:-./server}"

if [ "$SERVER_ENABLE" = "1" ] && [ -x /home/ctf/server ]; then
  echo "[+] server enabled, mode=$SERVER_MODE"

  if [ "$SERVER_MODE" = "daemon" ]; then
    "$CHROOT_BIN" /home/ctf /sh -c "$SERVER_CMD" &
    SERVER_PID=$!
    echo "[+] server started (pid=$SERVER_PID), listening on 127.0.0.1:${SERVER_INNER_PORT}"

    socat -T60 TCP-LISTEN:${SERVER_PORT},reuseaddr,fork TCP:127.0.0.1:${SERVER_INNER_PORT} &
    SERVER_FWD_PID=$!
    echo "[+] server forwarder started: 0.0.0.0:${SERVER_PORT} -> 127.0.0.1:${SERVER_INNER_PORT} (pid=$SERVER_FWD_PID)"
  else
    socat -T60 TCP-LISTEN:${SERVER_PORT},reuseaddr,fork EXEC:"$CHROOT_BIN /home/ctf ./server",stderr &
    SERVER_FWD_PID=$!
    echo "[+] server inetd started on :${SERVER_PORT} (pid=$SERVER_FWD_PID)"
  fi
else
  echo "[-] server not started (SERVER_ENABLE=$SERVER_ENABLE, or /home/ctf/server missing)"
fi

cleanup() {
  echo "[*] cleanup..."
  if [ "${SERVER_FWD_PID:-}" ]; then kill "$SERVER_FWD_PID" 2>/dev/null || true; fi
  if [ "${SERVER_PID:-}" ]; then kill "$SERVER_PID" 2>/dev/null || true; fi
}
trap cleanup INT TERM EXIT

PWN_PORT="${PWN_PORT:-8000}"
echo "[+] pwn service listen on :${PWN_PORT}"
exec socat -T60 TCP-LISTEN:${PWN_PORT},reuseaddr,fork EXEC:"$CHROOT_BIN /home/ctf ./pwn",stderr
