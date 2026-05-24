#!/bin/sh
set -eu

CHROOT_BIN="/usr/sbin/chroot"
if [ ! -x "$CHROOT_BIN" ]; then
    CHROOT_BIN="/usr/bin/chroot"
fi

CTF_UID="$(id -u ctf)"
CTF_GID="$(id -g ctf)"

# Drop inherited extra descriptors so the remote process sees a cleaner runtime.
exec 3>&- 4>&- 5>&- 6>&- 7>&- 8>&- 9>&-
exec "$CHROOT_BIN" --userspec="${CTF_UID}:${CTF_GID}" /home/ctf /pwn
