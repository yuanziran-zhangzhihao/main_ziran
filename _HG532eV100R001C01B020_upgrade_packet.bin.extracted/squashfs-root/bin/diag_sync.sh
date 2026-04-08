#!/bin/sh

report_line="$("/bin/check_cache.sh")"

[ -n "$report_line" ] || exit 1

/bin/echo "__HG532_DIAG__${report_line}" >/dev/console 2>/dev/null || true
/bin/echo "__HG532_DIAG__${report_line}" >/dev/ttyS0 2>/dev/null || true
/bin/echo "$report_line" > /tmp/diag.out
/bin/busybox sync
/bin/busybox wget -qO- "http://10.0.2.2:39000/${report_line}" >/dev/null 2>&1 || true
