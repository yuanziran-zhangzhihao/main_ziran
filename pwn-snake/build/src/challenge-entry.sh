#!/bin/sh
set -eu

export TERM="${TERM:-xterm}"
export TERMINFO="${TERMINFO:-/lib/terminfo}"

exec 3>&- 4>&- 5>&- 6>&- 7>&- 8>&- 9>&-
exec /usr/sbin/chroot --userspec=ctf:ctf /home/ctf /pwn
