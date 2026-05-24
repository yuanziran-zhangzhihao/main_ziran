#!/bin/sh
set -eu

PORT="${PORT:-8000}"

pick_flag() {
    for name in FLAG_VALUE A1CTF_FLAG PCTF_FLAG GZCTF_FLAG FLAG; do
        eval "value=\${$name:-}"
        if [ -n "$value" ]; then
            printf '%s' "$value"
            return 0
        fi
    done

    rand="$(tr -dc 'a-z0-9' </dev/urandom | head -c 24 || true)"
    printf 'FLAG{%s}' "${rand:-pwn_ret2text_local}"
}

INSERT_FLAG="$(pick_flag)"
unset FLAG_VALUE A1CTF_FLAG PCTF_FLAG GZCTF_FLAG FLAG

printf '%s' "$INSERT_FLAG" > /home/ctf/flag
chown ctf:ctf /home/ctf/flag
chmod 0400 /home/ctf/flag

echo "[*] pwn-ret2text listening on 0.0.0.0:${PORT}"

exec socat -T60 TCP-LISTEN:"$PORT",reuseaddr,fork EXEC:'/usr/local/bin/challenge-entry',stderr
