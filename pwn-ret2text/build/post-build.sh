#!/bin/bash
set -euo pipefail

# ==============================================
# 配置区：根据实际环境调整（通常无需修改）
# ==============================================
# 镜像标签（应与工作流中构建的镜像标签一致）
# 格式：ghcr.io/用户名/项目名:latest
IMAGE_TAG="${IMAGE_TAG:-ghcr.io/${GITHUB_REPOSITORY_OWNER}/${NAME}:latest}"

# 容器内文件路径（与 Dockerfile 中复制的路径对应）
CONTAINER_PWN_PATH="/home/ctf/pwn"
CONTAINER_LIBC_PATH="/home/ctf/lib/x86_64-linux-gnu/libc.so.6"
CONTAINER_LD_PATH="/home/ctf/lib64/ld-linux-x86-64.so.2"

# 宿主机附件目录（相对于脚本执行目录的上一级 attachments 文件夹）
ATTACHMENTS_DIR="../attachments"  # 从 build/ 到 pwn-ret2text/attachments


# ==============================================
# 执行逻辑：提取容器内文件到附件目录
# ==============================================
echo "===== Starting post-build attachment extraction ====="
echo "Target image: $IMAGE_TAG"
echo "Working directory: $(pwd)"
echo "Attachments directory: $(pwd)/$ATTACHMENTS_DIR"

# 1. 检查镜像是否存在
if ! docker image inspect "$IMAGE_TAG" &> /dev/null; then
    echo "❌ Error: Image $IMAGE_TAG not found locally. Ensure the image was built successfully."
    exit 1
fi

# 2. 从镜像创建临时容器（不启动）
echo "Creating temporary container from image..."
CONTAINER_ID=$(docker create "$IMAGE_TAG")
if [ -z "$CONTAINER_ID" ]; then
    echo "❌ Error: Failed to create container from image $IMAGE_TAG"
    exit 1
fi
echo "Temporary container created: $CONTAINER_ID"

cleanup() {
    docker rm -v "$CONTAINER_ID" &> /dev/null || true
}
trap cleanup EXIT

# 3. 创建附件目录（若不存在）
mkdir -p "$ATTACHMENTS_DIR"
echo "Attachments directory ready: $(cd "$ATTACHMENTS_DIR" && pwd)"

# 4. 复制文件（带错误检查）
copy_required_file() {
    local src="$1"
    local dest_dir="$2"
    local filename=$(basename "$src")
    
    if docker cp "$CONTAINER_ID:$src" "$dest_dir/" &> /dev/null; then
        echo "✅ Copied: $filename"
    else
        echo "❌ Error: Failed to copy required file $filename"
        exit 1
    fi
}

# 复制 pwn 文件
copy_required_file "$CONTAINER_PWN_PATH" "$ATTACHMENTS_DIR"

# 复制 libc 库
copy_required_file "$CONTAINER_LIBC_PATH" "$ATTACHMENTS_DIR"

# 复制 ld-linux 加载器
copy_required_file "$CONTAINER_LD_PATH" "$ATTACHMENTS_DIR"

echo "===== Attachment extraction completed ====="
echo "Files saved to: $(cd "$ATTACHMENTS_DIR" && pwd)"
ls -l "$ATTACHMENTS_DIR"
