#!/bin/sh
set -eu

if [ "${FLAG_VALUE:-}" ]; then
    INSERT_FLAG="$FLAG_VALUE"
    unset FLAG_VALUE
elif [ "${A1CTF_FLAG:-}" ]; then
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
chmod 0400 /home/ctf/flag

CHROOT_BIN="/usr/sbin/chroot"
if [ ! -x "$CHROOT_BIN" ]; then
  CHROOT_BIN="/usr/bin/chroot"
fi

CHROOT_USER="${CHROOT_USER:-ctf:ctf}"
if "$CHROOT_BIN" --help 2>&1 | grep -q -- '--userspec'; then
  CHROOT_PREFIX="$CHROOT_BIN --userspec=$CHROOT_USER /home/ctf"
else
  CHROOT_PREFIX="$CHROOT_BIN /home/ctf"
fi

SERVER_ENABLE="${SERVER_ENABLE:-1}"
SERVER_FORWARD_ENABLE="${SERVER_FORWARD_ENABLE:-0}"
SERVER_PORT="${SERVER_PORT:-8001}"
SERVER_INNER_PORT="${SERVER_INNER_PORT:-8080}"

if [ "$SERVER_ENABLE" = "1" ] && [ -x /home/ctf/server ]; then
  echo "[+] server enabled"
  sh -c "$CHROOT_PREFIX /server" &
  SERVER_PID=$!
  echo "[+] server started (pid=$SERVER_PID), listening on 127.0.0.1:${SERVER_INNER_PORT}"

  if [ "$SERVER_FORWARD_ENABLE" = "1" ]; then
    socat -T60 TCP-LISTEN:${SERVER_PORT},reuseaddr,fork TCP:127.0.0.1:${SERVER_INNER_PORT} &
    SERVER_FWD_PID=$!
    echo "[+] server forwarder started: 0.0.0.0:${SERVER_PORT} -> 127.0.0.1:${SERVER_INNER_PORT} (pid=$SERVER_FWD_PID)"
  else
    echo "[+] server forwarder disabled; only pwn service is exposed"
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
PWN_WRAPPER="/tmp/run-pwn.sh"
PWN_EXEC="$CHROOT_PREFIX /pwn"
if command -v stdbuf >/dev/null 2>&1; then
  PWN_EXEC="stdbuf -i0 -o0 -e0 $PWN_EXEC"
fi
cat > "$PWN_WRAPPER" <<EOF
#!/bin/sh
exec $PWN_EXEC
EOF
chmod 0755 "$PWN_WRAPPER"

echo "[+] pwn service listen on :${PWN_PORT}"
exec socat -T60 TCP-LISTEN:${PWN_PORT},reuseaddr,fork EXEC:"$PWN_WRAPPER",stderr
