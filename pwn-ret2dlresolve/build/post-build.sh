#!/bin/sh
set -eu

ATTACHMENTS_DIR="../attachments"
RUNTIME_DIR="./runtime"

echo "===== Preparing attachments ====="
mkdir -p "$ATTACHMENTS_DIR"

cp "$RUNTIME_DIR/home/ctf/pwn" "$ATTACHMENTS_DIR/pwn"
cp "$RUNTIME_DIR/lib/x86_64-linux-gnu/libc.so.6" "$ATTACHMENTS_DIR/libc.so.6"
cp "$RUNTIME_DIR/lib64/ld-linux-x86-64.so.2" "$ATTACHMENTS_DIR/ld-linux-x86-64.so.2"
cp ../solve.py "$ATTACHMENTS_DIR/solve.py"
cp ../README.md "$ATTACHMENTS_DIR/README.md"

echo "===== Attachment extraction completed ====="
ls -l "$ATTACHMENTS_DIR"
