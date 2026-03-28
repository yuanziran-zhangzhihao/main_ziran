#!/usr/bin/env bash
set -euo pipefail

cd /work

echo "[*] building user-space exploit"
make exp

kdir="$(find /usr/src -maxdepth 1 -type d -name 'linux-headers-[0-9]*-generic' | sort | tail -n 1 || true)"
if [ -z "$kdir" ]; then
    echo "[!] no packaged kernel headers found in /usr/src"
    exit 1
fi

kver="${kdir##*/linux-headers-}"
kimg="/boot/vmlinuz-$kver"
if [ ! -f "$kimg" ]; then
    echo "[!] matching kernel image not found: $kimg"
    exit 1
fi

echo "[*] building kernel module against $kdir"
make module KDIR="$kdir"
cp "$kimg" /work/bzImage

echo "[*] preparing initramfs"
staging="/tmp/babyioctl-initramfs"
rm -rf "$staging"
mkdir -p "$staging/bin" "$staging/sbin" "$staging/etc" "$staging/proc" \
         "$staging/sys" "$staging/dev" "$staging/tmp" "$staging/root" "$staging/home/ctf"

install -m 0755 /bin/busybox "$staging/bin/busybox"
for app in sh mount mkdir mknod insmod chmod chown ls cat echo dmesg poweroff uname sleep setsid cttyhack; do
    ln -sf busybox "$staging/bin/$app"
done

install -m 0755 initramfs/init "$staging/init"
install -m 0644 babydriver.ko "$staging/babydriver.ko"

mknod -m 600 "$staging/dev/console" c 5 1
mknod -m 666 "$staging/dev/null" c 1 3
mknod -m 666 "$staging/dev/tty" c 5 0

echo "[*] packing rootfs.cpio.gz"
(
    cd "$staging"
    find . -print0 | cpio --null -o --format=newc | gzip -9
) > /work/rootfs.cpio.gz

echo "[*] build complete"
echo "    kernel image : /work/bzImage"
echo "    initramfs    : /work/rootfs.cpio.gz"
echo "    module       : /work/babydriver.ko"
echo "    exploit      : /work/exp"
