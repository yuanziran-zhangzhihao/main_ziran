#!/usr/bin/env bash
set -euo pipefail

cd /work/quickjs-2024-01-13
make clean >/dev/null 2>&1 || true
make qjs

mkdir -p /work/dist
cp qjs /work/dist/qjs
cp /work/solve.js /work/dist/solve.js
cp /work/README.md /work/dist/README.md
cp quickjs-libc.c /work/dist/quickjs-libc.c.patched

tar -czf /work/dist/quickjs-uaf-baby.tar.gz \
  -C /work \
  README.md solve.js build.sh quickjs-2024-01-13

echo "[*] build complete"
ls -lh /work/dist
