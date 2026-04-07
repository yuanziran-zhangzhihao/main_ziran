#!/bin/sh

CACHE_FILE="${1:-/tmp/ctf.cache}"
EXPECTED_FILE="/etc/ctf.expected"
FLAG_FILE="/etc/ctf.flag"

if [ ! -f "$CACHE_FILE" ]; then
    echo "cache missing"
    exit 1
fi

if [ ! -f "$EXPECTED_FILE" ] || [ ! -f "$FLAG_FILE" ]; then
    echo "challenge files missing"
    exit 1
fi

cache_value="$(tr -d '\r\n' < "$CACHE_FILE")"
expected_value="$(tr -d '\r\n' < "$EXPECTED_FILE")"

if [ "$cache_value" != "$expected_value" ]; then
    echo "cache mismatch"
    exit 1
fi

cat "$FLAG_FILE"
