FROM debian:bookworm-slim

# 安装运行所需：socat + ldd(在 libc-bin 里)
RUN apt-get update && apt-get install -y --no-install-recommends \
    socat libc-bin ca-certificates coreutils \
    && rm -rf /var/lib/apt/lists/*

# 创建用户（供 chroot / 权限使用）
RUN groupadd -r ctf && useradd -r -g ctf -d /home/ctf -s /bin/sh ctf

# 准备 chroot 目录结构（/bin/sh 是 dash，不支持 {a,b} 花括号展开）
WORKDIR /home/ctf
RUN set -eux; \
    mkdir -p /home/ctf/bin /home/ctf/lib /home/ctf/lib64 /home/ctf/usr /home/ctf/dev /home/ctf/etc /home/ctf/tmp; \
    chmod 1777 /home/ctf/tmp

# 复制启动脚本 & 题目二进制
COPY src/start.sh /start.sh
RUN chmod +x /start.sh

COPY src/pwn /home/ctf/pwn
RUN chmod +x /home/ctf/pwn

# （可选）给 chroot 内提供基础命令：sh/cat/ls
# 关键：用 cp -L 解引用符号链接，避免拷贝到 chroot 后变断链
RUN set -eux; \
    copy_cmd() { \
      name="$1"; \
      src="$(command -v "$name")"; \
      cp -vL "$src" "/home/ctf/bin/$name"; \
      chmod 555 "/home/ctf/bin/$name"; \
    }; \
    copy_cmd sh; \
    copy_cmd cat; \
    copy_cmd ls

# 自动把依赖库复制到 chroot 根(/home/ctf)下对应路径
RUN set -eux; \
    copy_deps() { \
      bin="$1"; \
      ldd "$bin" | awk '{for (i=1;i<=NF;i++) if ($i ~ /^\\//) print $i}' | sort -u | \
      while read -r dep; do \
        [ -e "$dep" ] || continue; \
        dest="/home/ctf${dep}"; \
        mkdir -p "$(dirname "$dest")"; \
        cp -vL "$dep" "$dest"; \
      done; \
    }; \
    copy_deps /home/ctf/pwn; \
    copy_deps /home/ctf/bin/sh; \
    copy_deps /home/ctf/bin/cat; \
    copy_deps /home/ctf/bin/ls

# 放一些常见配置（部分程序可能会读取）
RUN set -eux; \
    cp -a /etc/nsswitch.conf /home/ctf/etc/ 2>/dev/null || true; \
    cp -a /etc/hosts       /home/ctf/etc/ 2>/dev/null || true; \
    cp -a /etc/resolv.conf /home/ctf/etc/ 2>/dev/null || true; \
    printf 'ctf:x:%s:%s:ctf:/home/ctf:/bin/sh\n' "$(id -u ctf)" "$(id -g ctf)" > /home/ctf/etc/passwd; \
    printf 'ctf:x:%s:\n' "$(id -g ctf)" > /home/ctf/etc/group

# 权限收紧（可选）
RUN set -eux; \
    chown -R root:root /home/ctf; \
    chown ctf:ctf /home/ctf; \
    chmod 755 /home/ctf

EXPOSE 8000
CMD ["/start.sh"]
