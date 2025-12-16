#!/bin/sh

if [ "$A1CTF_FLAG" ]; then
    INSERT_FLAG="$A1CTF_FLAG"
    unset A1CTF_FLAG
elif [ "$PCTF_FLAG" ]; then
    INSERT_FLAG="$PCTF_FLAG"
    unset PCTF_FLAG
elif [ "$GZCTF_FLAG" ]; then
    INSERT_FLAG="$GZCTF_FLAG"
    unset GZCTF_FLAG
elif [ "$FLAG" ]; then
    INSERT_FLAG="$FLAG"
    unset FLAG
else
    INSERT_FLAG="PCTF{!!!!_FLAG_ERROR_ASK_ADMIN_!!!!}"
fi

echo -n $INSERT_FLAG > /home/ctf/flag
INSERT_FLAG=""
chown ctf:ctf /home/ctf/flag

cp /bin/sh /home/ctf/sh && chmod +x /home/ctf/sh

socat -T60 TCP-LISTEN:8000,reuseaddr,fork EXEC:"/usr/sbin/chroot /home/ctf ./pwn",stderr
