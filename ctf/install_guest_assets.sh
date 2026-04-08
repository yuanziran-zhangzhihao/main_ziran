#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS_DIR="${ROOTFS_DIR:-$SCRIPT_DIR/../_HG532eV100R001C01B020_upgrade_packet.bin.extracted/squashfs-root}"
FLAG_VALUE="${FLAG_VALUE:-FLAG{change_me_at_runtime}}"
EXPECTED_CACHE_VALUE="${EXPECTED_CACHE_VALUE:-HG532_CACHE_OK}"

mkdir -p "$ROOTFS_DIR/bin" "$ROOTFS_DIR/etc"
chmod u+w "$ROOTFS_DIR/etc" 2>/dev/null || true
chmod u+w "$ROOTFS_DIR/etc/diag.profile" "$ROOTFS_DIR/etc/diag.token" 2>/dev/null || true
rm -f "$ROOTFS_DIR/etc/diag.profile" "$ROOTFS_DIR/etc/diag.token"
install -m 0755 "$SCRIPT_DIR/guest/check_cache.sh" "$ROOTFS_DIR/bin/check_cache.sh"
install -m 0755 "$SCRIPT_DIR/guest/diag_sync.sh" "$ROOTFS_DIR/bin/diag_sync.sh"
printf '%s\n' "$FLAG_VALUE" > "$ROOTFS_DIR/etc/diag.profile"
printf '%s\n' "$EXPECTED_CACHE_VALUE" > "$ROOTFS_DIR/etc/diag.token"
chmod 0400 "$ROOTFS_DIR/etc/diag.profile" "$ROOTFS_DIR/etc/diag.token"

echo "[+] guest CTF assets installed"
echo "[*] expected cache value: $EXPECTED_CACHE_VALUE"
echo "[*] runtime flag value: $FLAG_VALUE"
