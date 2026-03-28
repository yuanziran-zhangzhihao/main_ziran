#!/bin/bash
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-ghcr.io/${GITHUB_REPOSITORY_OWNER}/${NAME}:latest}"
ATTACHMENTS_DIR="../attachments"

CONTAINER_PWN_PATH="/home/ctf/pwn"
CONTAINER_LIBC_PATH="/home/ctf/lib/x86_64-linux-gnu/libc.so.6"
CONTAINER_LIBNCURSES_PATH="/home/ctf/lib/x86_64-linux-gnu/libncurses.so.6"
CONTAINER_LIBTINFO_PATH="/home/ctf/lib/x86_64-linux-gnu/libtinfo.so.6"
CONTAINER_LIBDL_PATH="/home/ctf/lib/x86_64-linux-gnu/libdl.so.2"
CONTAINER_LD_PATH_PRIMARY="/home/ctf/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2"
CONTAINER_LD_PATH_FALLBACK="/home/ctf/lib64/ld-linux-x86-64.so.2"

echo "===== Starting post-build attachment extraction ====="
echo "Target image: $IMAGE_TAG"
echo "Working directory: $(pwd)"
echo "Attachments directory: $(pwd)/$ATTACHMENTS_DIR"

if ! docker image inspect "$IMAGE_TAG" >/dev/null 2>&1; then
    echo "❌ Error: Image $IMAGE_TAG not found locally."
    exit 1
fi

CONTAINER_ID=$(docker create "$IMAGE_TAG")
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ Error: Failed to create container from image $IMAGE_TAG"
    exit 1
fi

cleanup() {
    docker rm -v "$CONTAINER_ID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

rm -rf "$ATTACHMENTS_DIR"
mkdir -p "$ATTACHMENTS_DIR"

echo "Attachments directory ready: $(cd "$ATTACHMENTS_DIR" && pwd)"

copy_file() {
    local src="$1"
    local dest_dir="$2"
    local filename
    filename=$(basename "$src")

    if docker cp "$CONTAINER_ID:$src" "$dest_dir/$filename" >/dev/null 2>&1; then
        echo "✅ Copied: $filename"
    else
        echo "❌ Error: Failed to copy $filename from $src"
        exit 1
    fi
}

copy_ld() {
    if docker cp "$CONTAINER_ID:$CONTAINER_LD_PATH_PRIMARY" "$ATTACHMENTS_DIR/ld-linux-x86-64.so.2" >/dev/null 2>&1; then
        echo "✅ Copied: ld-linux-x86-64.so.2"
        return
    fi

    if docker cp "$CONTAINER_ID:$CONTAINER_LD_PATH_FALLBACK" "$ATTACHMENTS_DIR/ld-linux-x86-64.so.2" >/dev/null 2>&1; then
        echo "✅ Copied: ld-linux-x86-64.so.2"
        return
    fi

    echo "❌ Error: Failed to copy ld-linux-x86-64.so.2 from container"
    exit 1
}

copy_file "$CONTAINER_PWN_PATH" "$ATTACHMENTS_DIR"
copy_file "$CONTAINER_LIBC_PATH" "$ATTACHMENTS_DIR"
copy_file "$CONTAINER_LIBNCURSES_PATH" "$ATTACHMENTS_DIR"
copy_file "$CONTAINER_LIBTINFO_PATH" "$ATTACHMENTS_DIR"
copy_file "$CONTAINER_LIBDL_PATH" "$ATTACHMENTS_DIR"
copy_ld

echo "===== Attachment extraction completed ====="
echo "Files saved to: $(cd "$ATTACHMENTS_DIR" && pwd)"
ls -l "$ATTACHMENTS_DIR"
