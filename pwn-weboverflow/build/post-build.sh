# 容器内文件路径
CONTAINER_PWN_PATH="/home/ctf/pwn"
CONTAINER_SERVER_PATH="/home/ctf/server"
CONTAINER_LIBC_PATH="/home/ctf/lib/x86_64-linux-gnu/libc.so.6"
CONTAINER_LD_PATH="/home/ctf/lib64/ld-linux-x86-64.so.2"

# 复制 pwn
copy_file "$CONTAINER_PWN_PATH" "$ATTACHMENTS_DIR"
# 复制 server
copy_file "$CONTAINER_SERVER_PATH" "$ATTACHMENTS_DIR"
# 复制 libc / ld
copy_file "$CONTAINER_LIBC_PATH" "$ATTACHMENTS_DIR"
copy_file "$CONTAINER_LD_PATH" "$ATTACHMENTS_DIR"
