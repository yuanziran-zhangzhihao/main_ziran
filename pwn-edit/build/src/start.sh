#!/bin/sh
set -eu

pick_flag() {
    if [ -n "${FLAG_VALUE:-}" ]; then
        printf '%s' "$FLAG_VALUE"
        return
    fi
    if [ -n "${A1CTF_FLAG:-}" ]; then
        printf '%s' "$A1CTF_FLAG"
        return
    fi
    if [ -n "${PCTF_FLAG:-}" ]; then
        printf '%s' "$PCTF_FLAG"
        return
    fi
    if [ -n "${GZCTF_FLAG:-}" ]; then
        printf '%s' "$GZCTF_FLAG"
        return
    fi
    if [ -n "${FLAG:-}" ]; then
        printf '%s' "$FLAG"
        return
    fi

    rand="$(tr -dc 'a-z0-9' </dev/urandom | head -c 24 || true)"
    printf 'FLAG{%s}' "${rand:-pwn_edit_local}"
}

INSERT_FLAG="$(pick_flag)"
export FLAG_VALUE="$INSERT_FLAG"
unset A1CTF_FLAG PCTF_FLAG GZCTF_FLAG FLAG

printf '%s' "$INSERT_FLAG" > /home/ctf/flag
chown ctf:ctf /home/ctf/flag

cp /bin/sh /home/ctf/sh
chmod +x /home/ctf/sh

echo "[*] pwn-edit listening on 0.0.0.0:8000"
echo "[*] runtime flag: $FLAG_VALUE"

exec socat -T60 TCP-LISTEN:8000,reuseaddr,fork EXEC:"/usr/local/bin/challenge-entry",stderr
