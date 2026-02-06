# 使用 Debian 作为基础镜像
FROM debian:bookworm-slim

# 安装 socat（和一些基础命令）
RUN apt-get update && apt-get install -y --no-install-recommends \
    socat \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 创建 ctf 用户和目录
RUN groupadd -r ctf && useradd -r -g ctf ctf && \
    mkdir -p /home/ctf && \
    chown ctf:ctf /home/ctf

# 复制启动脚本
COPY src/start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /home/ctf

# 复制题目二进制（pwn + server）
COPY src/pwn /home/ctf/pwn
COPY src/server /home/ctf/server
RUN chmod +x /home/ctf/pwn /home/ctf/server

# 在 chroot 里准备最小运行环境
# 关键：把二进制依赖的动态库拷进去（不仅仅是 libc/ld）
RUN set -eux; \
    mkdir -p /home/ctf; \
    # 拷贝二进制依赖库到 /home/ctf 下（保持原始路径结构）
    for bin in /home/ctf/pwn /home/ctf/server; do \
      if ldd "$bin" >/dev/null 2>&1; then \
        ldd "$bin" \
          | awk '($3 ~ /^\//){print $3} ($1 ~ /^\//){print $1}' \
          | sort -u \
          | xargs -r -I{} cp -v --parents {} /home/ctf; \
      fi; \
    done; \
    # 额外确保把动态加载器也放进去（x86_64 常见路径）
    if [ -f /lib64/ld-linux-x86-64.so.2 ]; then \
      cp -v --parents /lib64/ld-linux-x86-64.so.2 /home/ctf; \
    fi; \
    # 准备一些常用命令（可选）
    mkdir -p /home/ctf/bin && \
    cp /bin/sh /home/ctf/bin/ && \
    cp /bin/cat /home/ctf/bin/ && \
    cp /bin/ls /home/ctf/bin/ && \
    chmod +x /home/ctf/bin/*

# pwn 对外端口（默认 8000），server 对外端口（默认 8001）
EXPOSE 8000 8001

CMD ["/start.sh"]
