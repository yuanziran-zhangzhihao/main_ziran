FROM debian:bookworm-slim

# 只装运行期需要的：socat + ldd(在 libc-bin 里)；你要精简也可以后面删
RUN apt-get update && apt-get install -y --no-install-recommends \
    socat libc-bin ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 创建用户（供 chroot 里 userspec/权限用）
RUN groupadd -r ctf && useradd -r -g ctf -d /home/ctf -s /bin/sh ctf

# 准备 chroot 目录结构
WORKDIR /home/ctf
RUN mkdir -p /home/ctf/{bin,lib,lib64,usr,dev,etc,tmp} \
    && chmod 1733 /home/ctf/tmp

# 复制启动脚本 & 二进制
COPY src/start.sh /start.sh
RUN chmod +x /start.sh

COPY src/pwn /home/ctf/pwn
RUN chmod +x /home/ctf/pwn

# （可选）如果你需要在 chroot 里提供基础命令，就复制进去
# 注意：如果题目不需要这些命令，可以删掉这一段减少攻击面
RUN set -eux; \
    cp -a /bin/sh  /home/ctf/bin/; \
    cp -a /bin/cat /home/ctf/bin/; \
    cp -a /bin/ls  /home/ctf/bin/; \
    chmod 555 /home/ctf/bin/*

# 自动把依赖库复制到 chroot 根(/home/ctf)下对应路径
# 关键点：把 /lib/... 复制到 /home/ctf/lib/...，把 /lib64/... 复制到 /home/ctf/lib64/...
RUN set -eux; \
    copy_deps() { \
      bin="$1"; \
      ldd "$bin" | awk '{for (i=1;i<=NF;i++) if ($i ~ /^\\//) print $i}' | sort -u | \
      while read -r dep; do \
        [ -e "$dep" ] || continue; \
        dest="/home/ctf${dep}"; \
        mkdir -p "$(dirname "$dest")"; \
        cp -v "$dep" "$dest"; \
      done; \
    }; \
    copy_deps /home/ctf/pwn; \
    copy_deps /bin/sh; \
    copy_deps /bin/cat; \
    copy_deps /bin/ls

# 给 chroot 内放一些常用配置（有些程序会读取）
RUN set -eux; \
    cp -a /etc/nsswitch.conf /home/ctf/etc/ 2>/dev/null || true; \
    cp -a /etc/hosts       /home/ctf/etc/ 2>/dev/null || true; \
    cp -a /etc/resolv.conf /home/ctf/etc/ 2>/dev/null || true; \
    printf 'ctf:x:%s:%s:ctf:/home/ctf:/bin/sh\n' "$(id -u ctf)" "$(id -g ctf)" > /home/ctf/etc/passwd; \
    printf 'ctf:x:%s:\n' "$(id -g ctf)" > /home/ctf/etc/group

# 权限收紧（可选，但建议）
RUN chown -R root:root /home/ctf \
    && chown ctf:ctf /home/ctf \
    && chmod 755 /home/ctf

EXPOSE 8000
CMD ["/start.sh"]
