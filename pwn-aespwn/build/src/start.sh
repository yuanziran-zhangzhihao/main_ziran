#!/bin/sh
set -eu

PORT="${PORT:-8000}"

if [ -n "${A1CTF_FLAG:-}" ]; then
    INSERT_FLAG="$A1CTF_FLAG"
    unset A1CTF_FLAG
elif [ -n "${PCTF_FLAG:-}" ]; then
    INSERT_FLAG="$PCTF_FLAG"
    unset PCTF_FLAG
elif [ -n "${GZCTF_FLAG:-}" ]; then
    INSERT_FLAG="$GZCTF_FLAG"
    unset GZCTF_FLAG
elif [ -n "${FLAG:-}" ]; then
    INSERT_FLAG="$FLAG"
    unset FLAG
else
    INSERT_FLAG="PCTF{!!!!_FLAG_ERROR_ASK_ADMIN_!!!!}"
fi

printf '%s' "$INSERT_FLAG" > /home/ctf/flag
unset INSERT_FLAG
chown ctf:ctf /home/ctf/flag
chmod 0400 /home/ctf/flag

echo "[*] pwn-aespwn service listening on ${PORT}"

# Keep the challenge on plain stdin/stdout pipes so the post-success shell reads
# scripted commands normally. The smoke test sends the ciphertext immediately
# and does not rely on the unflushed prompt being visible first.
exec socat -T60 TCP-LISTEN:"$PORT",reuseaddr,fork EXEC:"/usr/local/bin/challenge-entry",stderr
