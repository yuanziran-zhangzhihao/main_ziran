#!/bin/sh
set -eu

PORT="${PORT:-8000}"

if [ -n "${A1CTF_FLAG:-}" ]; then
    INSERT_FLAG="$A1CTF_FLAG"
    unset A1CTF_FLAG
elif [ -n "${PCTF_FLAG:-}" ]; then
    INSERT_FLAG="$PCTF_FLAG"
    unset PCTF_FLAG
elif [ -n "${GZCTF_FLAG:-}" ]; then
    INSERT_FLAG="$GZCTF_FLAG"
    unset GZCTF_FLAG
elif [ -n "${FLAG:-}" ]; then
    INSERT_FLAG="$FLAG"
    unset FLAG
else
    INSERT_FLAG="PCTF{!!!!_FLAG_ERROR_ASK_ADMIN_!!!!}"
fi

printf '%s' "$INSERT_FLAG" > /home/ctf/flag
INSERT_FLAG=""
chown ctf:ctf /home/ctf/flag
chmod 0400 /home/ctf/flag

echo "[*] pwn-snake service listening on ${PORT}"

# The challenge is a curses TUI program, so it needs a PTY to render and flush
# interactively for remote players instead of behaving like a buffered pipe.
exec socat -T60 TCP-LISTEN:"$PORT",reuseaddr,fork EXEC:"/usr/local/bin/challenge-entry",pty,setsid,ctty,stderr
