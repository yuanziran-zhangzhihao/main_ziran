# pwn-weboverflow Platform Deploy

## 结论

- 默认只开放 `8000/tcp`
- 真实 flag 运行时通过 `FLAG_VALUE` 注入
- `8001` 调试转发默认关闭，只有显式设置 `SERVER_FORWARD_ENABLE=1` 才会开放

## 平台直传构建

平台如果支持上传目录后直接构建 Dockerfile，构建上下文用：

```bash
./pwn-weboverflow/build
```

默认构建命令：

```bash
docker build -t pwn-weboverflow ./pwn-weboverflow/build
```

如果平台拉 `docker.io/library/debian:bookworm-slim` 不稳定，可以覆盖基础镜像：

```bash
docker build \
  --build-arg BASE_IMAGE=ghcr.io/ziranan/core_level0:sha-8520c1b2d4c78c87e1662f215ad1fea300f2a8ab \
  -t pwn-weboverflow \
  ./pwn-weboverflow/build
```

## 运行方式

```bash
docker run --rm -p 8000:8000 -e 'FLAG_VALUE=FLAG{real_flag}' pwn-weboverflow
```

只在你确实需要调试后端 `server` 时，才额外开调试端口：

```bash
docker run --rm \
  -p 8000:8000 \
  -p 8001:8001 \
  -e 'FLAG_VALUE=FLAG{real_flag}' \
  -e SERVER_FORWARD_ENABLE=1 \
  pwn-weboverflow
```

## 黑盒自测

容器启动后，从宿主机执行：

```bash
python3 pwn-weboverflow/selftest/smoke.py --host 127.0.0.1 --port 8000
```

预期输出：

```text
[smoke] ok
```

## GitHub Actions 产物

当前 workflow 会：

- 构建并推送 `latest` 和 `sha-<commit>` 两个 tag
- 拉回 `sha-<commit>` 镜像做黑盒 smoke test
- 导出 `pwn/server/libc/ld` 附件
- 上传 `pwn-weboverflow-platform-direct.tar.gz`，可直接给平台使用
