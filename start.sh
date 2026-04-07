#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

QEMU_BIN="${QEMU_BIN:-qemu-system-mips}"
KERNEL_IMAGE="${KERNEL_IMAGE:-$SCRIPT_DIR/vmlinux-2.6.32-5-4kc-malta}"
DISK_IMAGE="${DISK_IMAGE:-$SCRIPT_DIR/debian_squeeze_mips_standard.qcow2}"
ROUTER_ROOTFS_IMAGE="${ROUTER_ROOTFS_IMAGE:-$SCRIPT_DIR/hg532-rootfs.ext2}"

SSH_FWD_PORT="${SSH_FWD_PORT:-2222}"
UPNP_FWD_PORT="${UPNP_FWD_PORT:-37215}"
GUEST_UPNP_PORT="${GUEST_UPNP_PORT:-37215}"
RAM_MB="${RAM_MB:-256}"

if ! command -v "$QEMU_BIN" >/dev/null 2>&1; then
    echo "[-] qemu binary not found: $QEMU_BIN" >&2
    exit 1
fi

if [[ ! -f "$KERNEL_IMAGE" ]]; then
    echo "[-] kernel image not found: $KERNEL_IMAGE" >&2
    exit 1
fi

if [[ ! -f "$DISK_IMAGE" ]]; then
    echo "[-] disk image not found: $DISK_IMAGE" >&2
    exit 1
fi

qemu_args=(
    -M malta
    -m "$RAM_MB"
    -kernel "$KERNEL_IMAGE"
    -drive "if=ide,index=0,media=disk,file=$DISK_IMAGE,format=qcow2"
    -append "root=/dev/sda1 console=tty0 nokaslr"
    -net nic,model=pcnet
    -net "user,hostfwd=tcp::${SSH_FWD_PORT}-:22,hostfwd=tcp::${UPNP_FWD_PORT}-:${GUEST_UPNP_PORT}"
    -nographic
)

echo "[*] kernel: $KERNEL_IMAGE"
echo "[*] disk:   $DISK_IMAGE"
echo "[*] ssh:    127.0.0.1:$SSH_FWD_PORT -> guest:22"
echo "[*] upnp:   127.0.0.1:$UPNP_FWD_PORT -> guest:$GUEST_UPNP_PORT"

if [[ -f "$ROUTER_ROOTFS_IMAGE" ]]; then
    echo "[*] router rootfs image: $ROUTER_ROOTFS_IMAGE"
    qemu_args+=( -drive "if=ide,index=1,media=disk,file=$ROUTER_ROOTFS_IMAGE,format=raw" )
else
    echo "[*] router rootfs image: not attached"
fi

exec "$QEMU_BIN" "${qemu_args[@]}"
