# HG532 Docker CTF Repo

这是一个已经整理好的 GitHub 上传目录，直接把这个目录初始化成仓库并推到 GitHub 即可。

## 目录特点

- 不包含 `debian_squeeze_mips_standard.qcow2` 这种超过 GitHub 普通仓库限制的大文件。
- Docker 构建时会自动下载 Debian MIPS kernel 和 qcow2。
- 固件 rootfs、flag 注入脚本、checker、GitHub Actions workflow 都已经带上。
- push 到 `CVE2017iot` 分支或打 `v*` tag 后，会自动构建并推送到 `ghcr.io`。
- 默认 PoC 会直接把 flag 弹到用户终端。

## 本地构建

```bash
docker build -t hg532-ctf .
```

## 本地运行

```bash
docker run --rm -it -p 37215:37215 -e FLAG_VALUE='FLAG{your_real_flag}' hg532-ctf
```

## GitHub 自动构建

工作流文件：`.github/workflows/docker-image.yml`

默认镜像名：

```bash
ghcr.io/<你的 GitHub 用户名>/<你的仓库名>:latest
```

拉取方式：

```bash
docker pull ghcr.io/<你的 GitHub 用户名>/<你的仓库名>:latest
```

运行方式：

```bash
docker run --rm -it -p 37215:37215 -e FLAG_VALUE='FLAG{your_real_flag}' ghcr.io/<你的 GitHub 用户名>/<你的仓库名>:latest
```

## 出题逻辑

选手利用 CVE-2017-17215 获得命令执行后，写入缓存并调用校验脚本：

```sh
echo HG532_CACHE_OK >/tmp/ctf.cache;/bin/check_cache.sh >/tmp/flag_out
```

外层 relay 会在利用成功后释放 `37215`，再把 `/tmp/flag_out` 的内容从同一个 `37215` 直接回给选手，所以仓库自带的 `exp.py` 直接回车就能拿到 flag。

```bash
python3 exp.py
```

## 注意

- `github-ready/` 默认只带占位 flag，真实 flag 请在部署容器时通过 `FLAG_VALUE` 注入。
- 出题平台如果只能开放一个端口，只开放 `37215` 即可。
- 如果你本地调试想进 guest，再额外映射 `-p 2222:2222`。
- 如果你手工写 PoC，不要把裸 `&` 直接塞进 `NewDownloadURL`，否则 XML 会坏。

## 自定义

运行容器时可以覆盖：

- `FLAG_VALUE`
- `EXPECTED_CACHE_VALUE`
- `TMUX_SESSION`
