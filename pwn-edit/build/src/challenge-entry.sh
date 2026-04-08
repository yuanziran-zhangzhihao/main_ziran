#!/bin/sh
set -eu

for fd in 3 4 5 6 7 8 9; do
    eval "exec ${fd}>&-" 2>/dev/null || true
done

exec /usr/sbin/chroot /home/ctf ./pwn
