#!/bin/sh
set -eu

FLAG_VALUE="PCTF{pwn_level1_heap_static_20260604}"
CTF_UID="${CTF_UID:-1000}"
CTF_GID="${CTF_GID:-1000}"

if [ -n "${A1CTF_FLAG:-}" ]; then
    FLAG_VALUE="$A1CTF_FLAG"
    unset A1CTF_FLAG
elif [ -n "${PCTF_FLAG:-}" ]; then
    FLAG_VALUE="$PCTF_FLAG"
    unset PCTF_FLAG
elif [ -n "${GZCTF_FLAG:-}" ]; then
    FLAG_VALUE="$GZCTF_FLAG"
    unset GZCTF_FLAG
elif [ -n "${FLAG:-}" ]; then
    FLAG_VALUE="$FLAG"
    unset FLAG
fi

printf '%s' "$FLAG_VALUE" > /home/ctf/flag
chown "$CTF_UID:$CTF_GID" /home/ctf/flag
chmod 0400 /home/ctf/flag

# The challenge binary already opens its own listening socket on port 6666.
/usr/sbin/chroot --userspec="${CTF_UID}:${CTF_GID}" /home/ctf /pwn &
PWN_PID="$!"

cleanup() {
    kill "$PWN_PID" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

READY=0
for _ in 1 2 3 4 5; do
    if ! kill -0 "$PWN_PID" 2>/dev/null; then
        wait "$PWN_PID"
        exit 1
    fi

    if grep -q ':1A0A ' /proc/net/tcp; then
        READY=1
        break
    fi

    sleep 1
done

if [ "$READY" -ne 1 ]; then
    echo "challenge listener on 6666 did not become ready" >&2
    exit 1
fi

exec socat -T60 TCP-LISTEN:8000,reuseaddr,fork TCP:127.0.0.1:6666
