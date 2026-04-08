#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-/out}"

mkdir -p "$OUT_DIR"
cp -a /opt/core_level0/attachments/. "$OUT_DIR/"

echo "[*] exported attachments to $OUT_DIR"
ls -lh "$OUT_DIR"
