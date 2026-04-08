#!/bin/bash
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-ghcr.io/${GITHUB_REPOSITORY_OWNER}/${NAME}:latest}"
ATTACHMENTS_DIR="../attachments"
CONTAINER_PWN_PATH="/home/ctf/pwn"

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
    echo "Error: failed to create container from image $IMAGE_TAG"
    exit 1
fi

cleanup() {
    docker rm -v "$CONTAINER_ID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

mkdir -p "$ATTACHMENTS_DIR"

copy_exact() {
    local src="$1"
    local dest="$2"

    if docker cp "$CONTAINER_ID:$src" "$dest" >/dev/null 2>&1; then
        echo "Copied: $(basename "$dest")"
        return 0
    fi

    return 1
}

copy_from_candidates() {
    local out_name="$1"
    shift

    for src in "$@"; do
        if copy_exact "$src" "$ATTACHMENTS_DIR/$out_name"; then
            return 0
        fi
    done

    echo "Error: failed to copy $out_name from container"
    printf 'Tried paths:\n' >&2
    for src in "$@"; do
        printf '  - %s\n' "$src" >&2
    done
    exit 1
}

copy_exact "$CONTAINER_PWN_PATH" "$ATTACHMENTS_DIR/pwn"

copy_from_candidates "libc.so.6" \
    "/home/ctf/lib/x86_64-linux-gnu/libc.so.6" \
    "/home/ctf/usr/lib/x86_64-linux-gnu/libc.so.6"

copy_from_candidates "libncurses.so.6" \
    "/home/ctf/lib/x86_64-linux-gnu/libncurses.so.6" \
    "/home/ctf/usr/lib/x86_64-linux-gnu/libncurses.so.6"

copy_from_candidates "libtinfo.so.6" \
    "/home/ctf/lib/x86_64-linux-gnu/libtinfo.so.6" \
    "/home/ctf/usr/lib/x86_64-linux-gnu/libtinfo.so.6"

copy_from_candidates "libdl.so.2" \
    "/home/ctf/lib/x86_64-linux-gnu/libdl.so.2" \
    "/home/ctf/usr/lib/x86_64-linux-gnu/libdl.so.2"

copy_from_candidates "ld-linux-x86-64.so.2" \
    "/home/ctf/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2" \
    "/home/ctf/lib64/ld-linux-x86-64.so.2"

echo "===== Attachment extraction completed ====="
ls -l "$ATTACHMENTS_DIR"
