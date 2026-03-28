#!/bin/sh
set -eu

FLAG_VALUE="PCTF{!!!!_FLAG_ERROR_ASK_ADMIN_!!!!}"

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
chown ctf:ctf /home/ctf/flag
chmod 0400 /home/ctf/flag

# The challenge is a one-shot stdin/stdout program, not a self-listening daemon.
# Keep socat as PID 1 and spawn a fresh chrooted instance for each TCP connection.
exec socat -T60 TCP-LISTEN:8000,reuseaddr,fork EXEC:'/usr/sbin/chroot --userspec=ctf /home/ctf /pwn',stderr
