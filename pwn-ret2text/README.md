# pwn-ret2text

这是一个面向新手的 64 位 Linux ret2text 题。

## 漏洞概况

- 程序只做一次 `read(0, buf, 0x100)`
- 栈缓冲区大小为 `0x40`
- `backdoor()` 直接执行 `system("/bin/sh")`
- 无 PIE、无 Canary，适合做最基础的返回地址覆盖

题目的预期利用就是覆盖返回地址，先用一个单独的 `ret` 对齐栈，再跳到 `backdoor()`，最后在拿到的 shell 里读取 `/flag`。

## 目录结构

- `build/src/pwn`: 题目二进制
- `build/src/start.sh`: 运行时 flag 注入和服务入口
- `build/src/challenge-entry.sh`: 每次连接拉起一份 chroot 内题目进程
- `build/smoke.py`: 黑盒 exploit smoke test
- `build/post-build.sh`: 从构建出的镜像提取附件

## 本地构建

```bash
docker build -t pwn-ret2text ./pwn-ret2text/build
```

## 本地运行

```bash
docker run --rm -p 8000:8000 -e 'FLAG_VALUE=FLAG{local_demo}' pwn-ret2text
```

服务只暴露一个端口：

```text
tcp/8000
```

## 本地冒烟

```bash
python3 ./pwn-ret2text/build/smoke.py \
  --host 127.0.0.1 \
  --port 8000 \
  --expect 'FLAG{local_demo}'
```

## 选手附件导出

```bash
cd ./pwn-ret2text/build
IMAGE_TAG=pwn-ret2text ./post-build.sh
```

导出的附件位于：

```text
./pwn-ret2text/attachments/
```

默认会包含：

- `pwn`
- `libc.so.6`
- `ld-linux-x86-64.so.2`

## GitHub Actions 交付链

工作流会自动完成：

1. 构建并推送 GHCR 镜像
2. 提取并上传选手附件
3. 拉起容器并执行一次 exploit smoke test
4. 失败时上传容器日志和进程信息

## 部署说明

- 真实 flag 不要写进仓库，通过运行时环境变量注入
- 支持的注入变量优先级为：
  `FLAG_VALUE`、`A1CTF_FLAG`、`PCTF_FLAG`、`GZCTF_FLAG`、`FLAG`
- 题目在容器里以单端口 `socat + chroot` 方式运行
- chroot 内会准备最小的 `sh`、`cat`、`ls` 和 glibc 依赖，保证选手拿到 shell 后能稳定读 flag
