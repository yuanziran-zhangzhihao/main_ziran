# 使用 Debian 作为基础镜像（不再使用无效的 builder 阶段）
FROM debian:bookworm-slim

# 安装 socat
RUN apt-get update && apt-get install -y --no-install-recommends \
    socat \
    && rm -rf /var/lib/apt/lists/*

# 创建 ctf 用户和目录
RUN groupadd -r ctf && useradd -r -g ctf ctf && \
    mkdir -p /home/ctf && \
    chown ctf:ctf /home/ctf

# 复制启动脚本（假设 start.sh 在 src/ 中）
COPY src/start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /home/ctf

# 复制题目二进制
COPY src/pwn .
RUN chmod +x pwn

# ✅ 关键修复：直接从当前 Debian 系统复制必要的库到容器内指定路径
# 注意：路径必须与 post-build.sh 中的 CONTAINER_*_PATH 一致
RUN mkdir -p /home/ctf/lib/x86_64-linux-gnu /home/ctf/lib64 && \
    cp /lib/x86_64-linux-gnu/libc.so.6 /home/ctf/lib/x86_64-linux-gnu/ && \
    cp /lib64/ld-linux-x86-64.so.2 /home/ctf/lib64/

# 创建 bin 目录并复制命令（可选，但不影响附件提取）
RUN mkdir -p /home/ctf/bin && \
    cp /bin/sh /home/ctf/bin/ && \
    cp /bin/cat /home/ctf/bin/ && \
    cp /bin/ls /home/ctf/bin/ && \
    chmod +x /home/ctf/bin/*

EXPOSE 8000

CMD ["/start.sh"]