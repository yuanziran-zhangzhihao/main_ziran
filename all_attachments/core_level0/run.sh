#!/usr/bin/env bash
set -euo pipefail

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "qemu-system-x86_64 not found"
    echo "Install QEMU first, then rerun ./run.sh"
    exit 1
fi

if [ ! -f ./bzImage ] || [ ! -f ./rootfs.cpio.gz ]; then
    echo "Missing ./bzImage or ./rootfs.cpio.gz"
    echo "Run: docker compose up --build builder"
    exit 1
fi

qemu-system-x86_64 \
    -m 256M \
    -smp 1 \
    -kernel ./bzImage \
    -initrd ./rootfs.cpio.gz \
    -append "console=ttyS0 loglevel=3 oops=panic panic=1 nokaslr pti=off quiet" \
    -nographic \
    -monitor /dev/null \
    -snapshot \
    -net none \
    -no-reboot
