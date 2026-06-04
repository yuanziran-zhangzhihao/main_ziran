#!/bin/sh
set -eu

PORT="${PORT:-8000}"

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
    INSERT_FLAG="PCTF{pwn_snake_manager_static_20260604}"
fi

printf '%s' "$INSERT_FLAG" > /home/ctf/flag
unset INSERT_FLAG
chown ctf:ctf /home/ctf/flag
chmod 0400 /home/ctf/flag

echo "[*] pwn-snake_manager service listening on ${PORT}"

exec socat -T60 TCP-LISTEN:"$PORT",reuseaddr,fork EXEC:"/usr/local/bin/challenge-entry",pty,ctty,stderr,setsid,sigint,rawer,echo=0
