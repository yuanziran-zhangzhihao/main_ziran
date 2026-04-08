#!/bin/sh
set -eu

# Drop inherited extra descriptors so the remote process sees a cleaner runtime.
exec 3>&- 4>&- 5>&- 6>&- 7>&- 8>&- 9>&-
exec /usr/sbin/chroot --userspec=ctf:ctf /home/ctf /pwn
