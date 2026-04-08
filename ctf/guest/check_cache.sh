#!/bin/sh

CACHE_FILE="${1:-/tmp/ctf.cache}"
EXPECTED_FILE="/etc/diag.token"
PROFILE_FILE="/etc/diag.profile"

if [ ! -f "$CACHE_FILE" ]; then
    echo "cache missing"
    exit 1
fi

if [ ! -f "$EXPECTED_FILE" ] || [ ! -f "$PROFILE_FILE" ]; then
    echo "diag profile missing"
    exit 1
fi

cache_value="$(cat "$CACHE_FILE")"
expected_value="$(cat "$EXPECTED_FILE")"

if [ "$cache_value" != "$expected_value" ]; then
    echo "diag cache mismatch"
    exit 1
fi

cat "$PROFILE_FILE"
