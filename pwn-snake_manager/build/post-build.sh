#!/bin/bash
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-ghcr.io/${GITHUB_REPOSITORY_OWNER}/${NAME}:latest}"
CONTAINER_PWN_PATH="/home/ctf/pwn"
CONTAINER_LIB_DIR="/home/ctf/lib/x86_64-linux-gnu"
CONTAINER_LD_PATH="/home/ctf/lib64/ld-linux-x86-64.so.2"
ATTACHMENTS_DIR="../attachments"

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

    if docker cp "$CONTAINER_ID:$src" "$dest_dir/" >/dev/null 2>&1; then
        echo "✅ Copied: $filename"
    else
        echo "❌ Error: Failed to copy $filename from $src"
        exit 1
    fi
}

copy_dir_contents() {
    local src_dir="$1"
    local dest_dir="$2"

    if docker cp "$CONTAINER_ID:$src_dir/." "$dest_dir/" >/dev/null 2>&1; then
        echo "✅ Copied shared libraries from: $src_dir"
    else
        echo "❌ Error: Failed to copy shared libraries from $src_dir"
        exit 1
    fi
}

copy_file "$CONTAINER_PWN_PATH" "$ATTACHMENTS_DIR"
copy_dir_contents "$CONTAINER_LIB_DIR" "$ATTACHMENTS_DIR"
copy_file "$CONTAINER_LD_PATH" "$ATTACHMENTS_DIR"

echo "===== Attachment extraction completed ====="
echo "Files saved to: $(cd "$ATTACHMENTS_DIR" && pwd)"
ls -l "$ATTACHMENTS_DIR"
