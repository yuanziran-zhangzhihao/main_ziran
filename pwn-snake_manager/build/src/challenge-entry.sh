#!/bin/sh
set -eu

CHROOT_BIN="/usr/sbin/chroot"
if [ ! -x "$CHROOT_BIN" ]; then
    CHROOT_BIN="/usr/bin/chroot"
fi

export TERM="${TERM:-xterm}"
export TERMINFO="${TERMINFO:-/usr/share/terminfo}"
export TERMINFO_DIRS="${TERMINFO_DIRS:-/etc/terminfo:/lib/terminfo:/usr/share/terminfo}"

CTF_UID="$(id -u ctf)"
CTF_GID="$(id -g ctf)"

exec 3>&- 4>&- 5>&- 6>&- 7>&- 8>&- 9>&-
exec "$CHROOT_BIN" --userspec="${CTF_UID}:${CTF_GID}" /home/ctf /bin/sh -c 'exec ./pwn'
