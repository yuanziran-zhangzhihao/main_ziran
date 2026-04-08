#!/bin/sh
set -eu

CHROOT_BIN="/usr/sbin/chroot"
if [ ! -x "$CHROOT_BIN" ]; then
    CHROOT_BIN="/usr/bin/chroot"
fi

exec 3>&- 4>&- 5>&- 6>&- 7>&- 8>&- 9>&-
exec "$CHROOT_BIN" --userspec=ctf:ctf /home/ctf /pwn
