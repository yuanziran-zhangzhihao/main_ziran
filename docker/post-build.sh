#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-ghcr.io/${GITHUB_REPOSITORY_OWNER}/${NAME}:latest}"
ATTACHMENTS_DIR="${ATTACHMENTS_DIR:-attachments}"
SMOKE_DIR="${SMOKE_DIR:-smoke}"

echo "===== Starting core_level0 post-build extraction ====="
echo "Target image: $IMAGE_TAG"

if ! docker image inspect "$IMAGE_TAG" >/dev/null 2>&1; then
    echo "Image not present locally, pulling..."
    docker pull "$IMAGE_TAG"
fi

CONTAINER_ID="$(docker create "$IMAGE_TAG")"
trap 'docker rm -v "$CONTAINER_ID" >/dev/null 2>&1 || true' EXIT

rm -rf "$ATTACHMENTS_DIR" "$SMOKE_DIR"
mkdir -p "$ATTACHMENTS_DIR" "$SMOKE_DIR"

docker cp "$CONTAINER_ID:/opt/core_level0/attachments/." "$ATTACHMENTS_DIR/"
docker cp "$CONTAINER_ID:/opt/core_level0/selftest/exp.static" "$SMOKE_DIR/exp.static"

echo "===== Extraction complete ====="
ls -lh "$ATTACHMENTS_DIR"
ls -lh "$SMOKE_DIR"
