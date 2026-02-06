# 使用 Debian 作为基础镜像
FROM debian:bookworm-slim

# 安装 socat + 运行依赖库（修复 libncurses.so.6 not found）
# 顺带装一些常见运行时库，避免后续再缺
RUN apt-get update && apt-get install -y --no-install-recommends \
    socat \
    libncurses6 \
    libtinfo6 \
    libstdc++6 \
    libgcc-s1 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 创建 ctf 用户和目录
RUN groupadd -r ctf && useradd -r -g ctf ctf && \
    mkdir -p /home/ctf && \
    chown -R ctf:ctf /home/ctf

# 复制启动脚本
COPY src/start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /home/ctf

# 复制题目二进制
COPY src/pwn /home/ctf/pwn
RUN chmod +x /home/ctf/pwn

# （可选但推荐）把 pwn 的动态库依赖复制到 /home/ctf 下（适配 chroot / 附件打包）
# 这样不再需要手工 cp libc/ld 等，依赖都自动带上
RUN set -eux; \
    mkdir -p /home/ctf/lib /home/ctf/lib64; \
    ldd /home/ctf/pwn | awk '{ \
        if ($1 ~ /^\//) print $1; \
        if ($3 ~ /^\//) print $3; \
    }' | sort -u | while read -r so; do \
        # 把 /lib/x86_64-linux-gnu/xxx.so.* 这种路径按原目录结构复制到 /home/ctf/
        cp -v --parents "$so" /home/ctf/; \
    done; \
    # 再确保动态加载器也带上（有些 ldd 不会用同一字段输出它）
    if [ -f /lib64/ld-linux-x86-64.so.2 ]; then \
        cp -v --parents /lib64/ld-linux-x86-64.so.2 /home/ctf/; \
    fi; \
    # 有的系统加载器在 /lib/x86_64-linux-gnu/ 下，也兜底复制
    if [ -f /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 ]; then \
        cp -v --parents /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /home/ctf/; \
    fi

# 创建 bin 目录并复制命令（如果你有 chroot / 附件环境会用到）
RUN mkdir -p /home/ctf/bin && \
    cp /bin/sh /home/ctf/bin/ && \
    cp /bin/cat /home/ctf/bin/ && \
    cp /bin/ls /home/ctf/bin/ && \
    chmod +x /home/ctf/bin/*

EXPOSE 8000

CMD ["/start.sh"]
