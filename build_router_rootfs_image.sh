#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS_DIR="${ROOTFS_DIR:-$SCRIPT_DIR/_HG532eV100R001C01B020_upgrade_packet.bin.extracted/squashfs-root}"
OUTPUT_IMAGE="${OUTPUT_IMAGE:-$SCRIPT_DIR/hg532-rootfs.ext2}"
EXTRA_MB="${EXTRA_MB:-64}"
MIN_MB="${MIN_MB:-64}"
ROUND_MB="${ROUND_MB:-4}"

restore_exec_bits() {
    local rel

    # GitHub checkout drops execute bits for many extracted firmware files.
    # Restore the directories the router boot chain actually executes from.
    for rel in bin sbin lib usr/bin usr/sbin usr/lib etc/init.d; do
        if [[ -d "$ROOTFS_DIR/$rel" ]]; then
            find "$ROOTFS_DIR/$rel" -type f -exec chmod 0755 {} +
        fi
    done

    if [[ -f "$ROOTFS_DIR/etc/profile" ]]; then
        chmod 0755 "$ROOTFS_DIR/etc/profile"
    fi
}

normalize_rootfs_line_endings() {
    local path=""
    local candidates=(
        "$ROOTFS_DIR/etc/profile"
        "$ROOTFS_DIR/etc/diag.profile"
        "$ROOTFS_DIR/etc/inittab"
    )

    if [[ -d "$ROOTFS_DIR/etc/init.d" ]]; then
        while IFS= read -r -d '' path; do
            candidates+=("$path")
        done < <(find "$ROOTFS_DIR/etc/init.d" -type f -print0)
    fi

    for path in "${candidates[@]}"; do
        if [[ -f "$path" ]]; then
            sed -i 's/\r$//' "$path"
        fi
    done
}

restore_flattened_symlinks() {
    local path=""
    local target=""
    local resolved=""
    local candidates=()
    local rel

    # Windows checkouts often materialize extracted firmware symlinks as
    # tiny text files whose contents are the original link target.
    if [[ -f "$ROOTFS_DIR/init" ]]; then
        candidates+=("$ROOTFS_DIR/init")
    fi

    for rel in bin sbin lib usr/bin usr/sbin usr/lib; do
        if [[ -e "$ROOTFS_DIR/$rel" ]]; then
            candidates+=("$ROOTFS_DIR/$rel")
        fi
    done

    if (( ${#candidates[@]} == 0 )); then
        return 0
    fi

    while IFS= read -r -d '' path; do
        target="$(tr -d '\r\n' < "$path")"

        [[ -n "$target" ]] || continue
        [[ "$target" =~ ^[A-Za-z0-9._/+:-]+$ ]] || continue

        if [[ "$target" == /* ]]; then
            resolved="$ROOTFS_DIR/$target"
        else
            resolved="$(dirname "$path")/$target"
        fi

        if [[ -e "$resolved" ]]; then
            rm -f "$path"
            ln -s "$target" "$path"
        fi
    done < <(find "${candidates[@]}" -type f -size -128c -print0)
}

if [[ ! -d "$ROOTFS_DIR" ]]; then
    echo "[-] router rootfs directory not found: $ROOTFS_DIR" >&2
    exit 1
fi

if ! command -v mkfs.ext2 >/dev/null 2>&1; then
    echo "[-] mkfs.ext2 not found" >&2
    exit 1
fi

normalize_rootfs_line_endings
restore_exec_bits
restore_flattened_symlinks

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
