#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS_DIR="${ROOTFS_DIR:-$SCRIPT_DIR/_HG532eV100R001C01B020_upgrade_packet.bin.extracted/squashfs-root}"
OUTPUT_IMAGE="${OUTPUT_IMAGE:-$SCRIPT_DIR/hg532-rootfs.ext2}"
EXTRA_MB="${EXTRA_MB:-64}"
MIN_MB="${MIN_MB:-64}"
ROUND_MB="${ROUND_MB:-4}"

if [[ ! -d "$ROOTFS_DIR" ]]; then
    echo "[-] router rootfs directory not found: $ROOTFS_DIR" >&2
    exit 1
fi

if ! command -v mkfs.ext2 >/dev/null 2>&1; then
    echo "[-] mkfs.ext2 not found" >&2
    exit 1
fi

used_kb="$(du -sk "$ROOTFS_DIR" | awk '{print $1}')"
size_kb="$((used_kb + EXTRA_MB * 1024))"
min_kb="$((MIN_MB * 1024))"
round_kb="$((ROUND_MB * 1024))"

if (( size_kb < min_kb )); then
    size_kb="$min_kb"
fi

size_kb="$((((size_kb + round_kb - 1) / round_kb) * round_kb))"
tmp_image="${OUTPUT_IMAGE}.tmp"

rm -f "$tmp_image"
truncate -s "${size_kb}K" "$tmp_image"
mkfs.ext2 -q -F -L HG532ROOT -d "$ROOTFS_DIR" "$tmp_image"
mv -f "$tmp_image" "$OUTPUT_IMAGE"

echo "[+] router rootfs image rebuilt: $OUTPUT_IMAGE"
echo "[*] source: $ROOTFS_DIR"
echo "[*] size:   ${size_kb} KiB"
