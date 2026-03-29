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
    INSERT_FLAG="PCTF{!!!!_FLAG_ERROR_ASK_ADMIN_!!!!}"
fi

printf '%s' "$INSERT_FLAG" > /home/ctf/flag
unset INSERT_FLAG
chown ctf:ctf /home/ctf/flag

cp /bin/sh /home/ctf/sh
chmod +x /home/ctf/sh

CHROOT_BIN="/usr/sbin/chroot"
if [ ! -x "$CHROOT_BIN" ]; then
    CHROOT_BIN="/usr/bin/chroot"
fi

export TERM="xterm"
export TERMINFO="/usr/share/terminfo"
export TERMINFO_DIRS="/etc/terminfo:/lib/terminfo:/usr/share/terminfo"
exec socat -T60 TCP-LISTEN:8000,reuseaddr,fork EXEC:"$CHROOT_BIN /home/ctf /bin/sh -c 'TERM=xterm TERMINFO=/usr/share/terminfo TERMINFO_DIRS=/etc/terminfo:/lib/terminfo:/usr/share/terminfo exec ./pwn'",pty,ctty,stderr,setsid,sigint,sane
