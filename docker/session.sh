#!/usr/bin/env bash
set -euo pipefail

: "${CORE_LEVEL0_BZIMAGE:?missing kernel path}"
: "${CORE_LEVEL0_INITRD:?missing initrd path}"

SESSION_TIMEOUT="${SESSION_TIMEOUT:-300}"

exec timeout --foreground "${SESSION_TIMEOUT}" qemu-system-x86_64 \
    -m 256M \
    -smp 1 \
    -kernel "$CORE_LEVEL0_BZIMAGE" \
    -initrd "$CORE_LEVEL0_INITRD" \
    -append "console=ttyS0 loglevel=3 oops=panic panic=1 nokaslr pti=off quiet" \
    -nographic \
    -monitor /dev/null \
    -snapshot \
    -net none \
    -no-reboot
