#!/bin/sh
set -eu

# ----------------------------
# 1) 写入 flag（你原来的逻辑）
# ----------------------------
if [ "${A1CTF_FLAG:-}" ]; then
    INSERT_FLAG="$A1CTF_FLAG"
    unset A1CTF_FLAG
elif [ "${PCTF_FLAG:-}" ]; then
    INSERT_FLAG="$PCTF_FLAG"
    unset PCTF_FLAG
elif [ "${GZCTF_FLAG:-}" ]; then
    INSERT_FLAG="$GZCTF_FLAG"
    unset GZCTF_FLAG
elif [ "${FLAG:-}" ]; then
    INSERT_FLAG="$FLAG"
    unset FLAG
else
    INSERT_FLAG="PCTF{!!!!_FLAG_ERROR_ASK_ADMIN_!!!!}"
fi

echo -n "$INSERT_FLAG" > /home/ctf/flag
INSERT_FLAG=""
chown ctf:ctf /home/ctf/flag

# chroot 内提供 /sh（方便用 sh -c 执行命令）
cp /bin/sh /home/ctf/sh && chmod +x /home/ctf/sh

CHROOT_BIN="/usr/sbin/chroot"
if [ ! -x "$CHROOT_BIN" ]; then
  CHROOT_BIN="/usr/bin/chroot"
fi

# ----------------------------
# 2) 启动 server（可选）
# ----------------------------
SERVER_ENABLE="${SERVER_ENABLE:-1}"
SERVER_MODE="${SERVER_MODE:-daemon}"       # daemon | inetd
SERVER_PORT="${SERVER_PORT:-8001}"         # 对外端口
SERVER_INNER_PORT="${SERVER_INNER_PORT:-9000}"  # daemon 模式下 server 实际监听端口
SERVER_CMD="${SERVER_CMD:-./server}"       # daemon 模式下在 chroot 内执行的命令

if [ "$SERVER_ENABLE" = "1" ] && [ -x /home/ctf/server ]; then
  echo "[+] server enabled, mode=$SERVER_MODE"

  if [ "$SERVER_MODE" = "daemon" ]; then
    # daemon 模式：server 常驻运行（你需要确保它会自己 listen 一个端口）
    # 如果你的 server 支持指定端口，建议在 workflow/平台里设置：
    # SERVER_CMD="./server --port ${SERVER_INNER_PORT}"
    "$CHROOT_BIN" /home/ctf /sh -c "$SERVER_CMD" &
    SERVER_PID=$!
    echo "[+] server started (pid=$SERVER_PID), expecting listen on 127.0.0.1:${SERVER_INNER_PORT}"

    # 用 socat 把外部的 SERVER_PORT 转发到 server 的实际监听端口
    socat -T60 TCP-LISTEN:${SERVER_PORT},reuseaddr,fork TCP:127.0.0.1:${SERVER_INNER_PORT} &
    SERVER_FWD_PID=$!
    echo "[+] server forwarder started: 0.0.0.0:${SERVER_PORT} -> 127.0.0.1:${SERVER_INNER_PORT} (pid=$SERVER_FWD_PID)"

  else
    # inetd 模式：每个连接启动一次 server（和 pwn 类似）
    socat -T60 TCP-LISTEN:${SERVER_PORT},reuseaddr,fork EXEC:"$CHROOT_BIN /home/ctf ./server",stderr &
    SERVER_FWD_PID=$!
    echo "[+] server inetd started on :${SERVER_PORT} (pid=$SERVER_FWD_PID)"
  fi
else
  echo "[-] server not started (SERVER_ENABLE=$SERVER_ENABLE, or /home/ctf/server missing)"
fi

# 退出时清理后台进程
cleanup() {
  echo "[*] cleanup..."
  if [ "${SERVER_FWD_PID:-}" ]; then kill "$SERVER_FWD_PID" 2>/dev/null || true; fi
  if [ "${SERVER_PID:-}" ]; then kill "$SERVER_PID" 2>/dev/null || true; fi
}
trap cleanup INT TERM EXIT

# ----------------------------
# 3) 启动 pwn（前台保持容器存活）
# ----------------------------
PWN_PORT="${PWN_PORT:-8000}"
echo "[+] pwn service listen on :${PWN_PORT}"
exec socat -T60 TCP-LISTEN:${PWN_PORT},reuseaddr,fork EXEC:"$CHROOT_BIN /home/ctf ./pwn",stderr
