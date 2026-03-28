#!/bin/bash
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-ghcr.io/${GITHUB_REPOSITORY_OWNER}/${NAME}:latest}"
CONTAINER_PWN_PATH="/home/ctf/pwn"
CONTAINER_LIBC_PATH="/home/ctf/libc.so.6"
CONTAINER_LD_PATH="/home/ctf/ld-linux-x86-64.so.2"
ATTACHMENTS_DIR="../attachments"

echo "===== Starting post-build attachment extraction ====="
echo "Target image: $IMAGE_TAG"

if ! docker image inspect "$IMAGE_TAG" >/dev/null 2>&1; then
    echo "Image $IMAGE_TAG is not loaded locally. Attempting docker pull..."
    docker pull "$IMAGE_TAG"
fi

if ! docker image inspect "$IMAGE_TAG" >/dev/null 2>&1; then
    echo "Error: image $IMAGE_TAG is unavailable."
    exit 1
fi

CONTAINER_ID="$(docker create "$IMAGE_TAG")"
if [ -z "$CONTAINER_ID" ]; then
    echo "Error: failed to create container from $IMAGE_TAG"
    exit 1
fi

trap 'docker rm -v "$CONTAINER_ID" >/dev/null 2>&1 || true' EXIT

mkdir -p "$ATTACHMENTS_DIR"

copy_file() {
    local src="$1"
    local dest_dir="$2"
    local filename
    filename="$(basename "$src")"

    if docker cp "$CONTAINER_ID:$src" "$dest_dir/" >/dev/null 2>&1; then
        echo "Copied: $filename"
    else
        echo "Warning: failed to copy $filename"
    fi
}

copy_file "$CONTAINER_PWN_PATH" "$ATTACHMENTS_DIR"
copy_file "$CONTAINER_LIBC_PATH" "$ATTACHMENTS_DIR"
copy_file "$CONTAINER_LD_PATH" "$ATTACHMENTS_DIR"

docker rm -v "$CONTAINER_ID" >/dev/null 2>&1
trap - EXIT

echo "===== Attachment extraction completed ====="
ls -l "$ATTACHMENTS_DIR"
