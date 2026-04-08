#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -d /work/quickjs-2024-01-13 ]]; then
  REPO_ROOT="/work"
else
  REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi

OUT_ROOT="${1:-$REPO_ROOT}"
DIST_DIR="$OUT_ROOT/dist"

cd "$REPO_ROOT/quickjs-2024-01-13"
make clean >/dev/null 2>&1 || true
make qjs

mkdir -p "$DIST_DIR"
cp qjs "$DIST_DIR/qjs"
cp "$REPO_ROOT/player/README.md" "$DIST_DIR/README.md"
cp quickjs-libc.c "$DIST_DIR/quickjs-libc.c.patched"

tar -czf "$DIST_DIR/quickjs-uaf-baby.tar.gz" \
  -C "$REPO_ROOT" \
  build.sh player quickjs-2024-01-13

echo "[*] build complete"
ls -lh "$DIST_DIR"
