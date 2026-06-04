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
    INSERT_FLAG="PCTF{bypass_login_heap_pointer_ret2backdoor}"
fi

printf '%s' "$INSERT_FLAG" > /home/ctf/flag
unset INSERT_FLAG
chown ctf:ctf /home/ctf/flag

echo "pwn-bypass service listening on 8000"

exec socat -T60 TCP-LISTEN:8000,reuseaddr,fork SYSTEM:"/usr/sbin/chroot /home/ctf ./pwn 2>&1 | tee /proc/1/fd/1"
