# pwn-weboverflow

这个分支已经整理成可直接部署的单端口题目，选手入口默认只有 `8000/tcp`。

构建：

```bash
docker build -t pwn-weboverflow ./pwn-weboverflow/build
```

如果当前环境拉 `docker.io/library/debian:bookworm-slim` 不稳定，可以改用已经可访问的基础镜像：

```bash
docker build \
  --build-arg BASE_IMAGE=ghcr.io/ziranan/core_level0:sha-8520c1b2d4c78c87e1662f215ad1fea300f2a8ab \
  -t pwn-weboverflow \
  ./pwn-weboverflow/build
```

运行：

```bash
docker run --rm -p 8000:8000 -e 'FLAG_VALUE=FLAG{demo_flag}' pwn-weboverflow
```

自测：

```bash
python3 pwn-weboverflow/selftest/smoke.py --host 127.0.0.1 --port 8000
```

更完整的部署说明见 [pwn-weboverflow/PLATFORM_DEPLOY.md](pwn-weboverflow/PLATFORM_DEPLOY.md)。
