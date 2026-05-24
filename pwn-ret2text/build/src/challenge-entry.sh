#!/bin/sh
set -eu

CHROOT_BIN="/usr/sbin/chroot"
if [ ! -x "$CHROOT_BIN" ]; then
    CHROOT_BIN="/usr/bin/chroot"
fi

for fd in 3 4 5 6 7 8 9; do
    eval "exec ${fd}>&-" 2>/dev/null || true
done

CTF_UID="$(id -u ctf)"
CTF_GID="$(id -g ctf)"

exec "$CHROOT_BIN" --userspec="${CTF_UID}:${CTF_GID}" /home/ctf ./pwn
