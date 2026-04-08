# pwn-ret2dlresolve

这是一个面向 `ret2dlresolve` 入门的 64 位栈溢出题。

## Challenge Shape

- 架构：`amd64`
- 保护：`Partial RELRO`, `NX`, `No PIE`, `No Canary`
- 目标：通过一次栈溢出构造 `ret2dlresolve`，解析并执行 `/bin/sh`
- flag：运行时注入到容器内 `/home/ctf/flag`

## Files

- `build/src/challenge.c`: 题目源码
- `build/src/launcher.c`: 静态 launcher，负责注入 flag 并监听单端口
- `build/Makefile`: 构建运行时目录
- `build/Dockerfile`: `scratch` 运行镜像
- `solve.py`: 参考利用和 smoke test

## Local Build

```bash
make -C build runtime
```

## Docker Run

```bash
FLAG_VALUE='flag{local_demo}' docker compose up --build -d
```

服务默认监听：

```text
127.0.0.1:8000
```

## Reference Solve

```bash
python3 solve.py --host 127.0.0.1 --port 8000 --expect 'flag{local_demo}'
```

## Deployment Notes

- 容器只暴露 `8000/tcp`
- 真实 flag 通过 `FLAG_VALUE`、`FLAG`、`PCTF_FLAG`、`GZCTF_FLAG` 或 `A1CTF_FLAG` 注入
- launcher 会把 flag 写入 `/home/ctf/flag` 后清理环境变量，避免在 shell 里直接 `env` 泄露
- 镜像不依赖外网基础镜像，构建前先执行 `make -C build runtime`
