FROM ubuntu:24.04 AS builder
#
# 使用 Debian 镜像
FROM debian:bookworm-slim

# 安装必要软件
RUN apt-get update && apt-get install -y --no-install-recommends \
    socat \
    && rm -rf /var/lib/apt/lists/*

# 创建 ctf 用户和目录
RUN groupadd -r ctf && useradd -r -g ctf ctf && \
    mkdir -p /home/ctf && \
    chown ctf:ctf /home/ctf

COPY src/start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /home/ctf/

# 复制 pwn 文件并设置权限
COPY src/pwn .
RUN chmod +x pwn

# 复制必要的库
COPY --from=builder /lib64/ld-linux-x86-64.so.2 /home/ctf/lib64/
COPY --from=builder /lib/x86_64-linux-gnu/libc.so.6 /home/ctf/lib/x86_64-linux-gnu/

# 创建 bin 目录并复制命令
RUN mkdir -p /home/ctf/bin && \
    cp /bin/sh /home/ctf/bin/ && \
    cp /bin/cat /home/ctf/bin/ && \
    cp /bin/ls /home/ctf/bin/ && \
    chmod +x /home/ctf/bin/*

EXPOSE 60

CMD ["/start.sh"]