# HG532 Docker CTF Repo

这是一个已经整理好的 GitHub 上传目录，直接把这个目录初始化成仓库并推到 GitHub 即可。

## 目录特点

- 不包含 `debian_squeeze_mips_standard.qcow2` 这种超过 GitHub 普通仓库限制的大文件。
- Docker 构建时会自动下载 Debian MIPS kernel 和 qcow2。
- 固件 rootfs、flag 注入脚本、checker、GitHub Actions workflow 都已经带上。
- push 到 `CVE2017iot` 分支或打 `v*` tag 后，可以自动构建并推送到 `ghcr.io`。
- 默认 PoC 会直接把 flag 弹到用户终端。
- 当前运行链已经去掉对平台宿主机 `tmux` 的依赖。
- 镜像内保留了 `tmux`、`sshpass`、`nc`、`ss` 这类调试/兼容工具，尽量别把平台环境想得过于理想。

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

平台部署说明：`PLATFORM_DEPLOY.md`

当前 workflow 不只是构建镜像，也会拉起容器做一次黑盒 smoke test；如果失败，会额外上传 `hg532-smoke-logs` 方便排障。

另外会额外上传一组可直接给平台使用的附件：

- `hg532-deploy-bundles/cve2017iot-hg532-image.tar.gz`
- `hg532-deploy-bundles/cve2017iot-platform-direct.tar.gz`

注意：这套 GitHub Actions 只是一个可选分发方式，不是平台部署前提。如果你的出题平台不会从 GHCR 拉镜像，可以直接上传 `github-ready/` 目录，让平台按 `Dockerfile` 本地构建。

默认镜像名：

```bash
ghcr.io/<你的 GitHub 用户名>/cve2017iot-hg532:latest
```

拉取方式：

```bash
docker pull ghcr.io/<你的 GitHub 用户名>/cve2017iot-hg532:latest
```

运行方式：

```bash
docker run --rm -it -p 37215:37215 -e FLAG_VALUE='FLAG{your_real_flag}' ghcr.io/<你的 GitHub 用户名>/cve2017iot-hg532:latest
```

当前 workflow 在推送 `CVE2017iot` 分支后，默认会生成这些 tag：

```bash
ghcr.io/<你的 GitHub 用户名>/cve2017iot-hg532:latest
ghcr.io/<你的 GitHub 用户名>/cve2017iot-hg532:cve2017iot
ghcr.io/<你的 GitHub 用户名>/cve2017iot-hg532:sha-<提交短哈希>
```

如果你要给出题平台填固定镜像，优先用：

```bash
ghcr.io/<你的 GitHub 用户名>/cve2017iot-hg532:sha-<提交短哈希>
```

不要只依赖 `latest`，这样能避免平台缓存旧镜像。

## 平台部署建议

如果你的出题平台支持“上传目录/仓库后直接构建 Dockerfile”，优先走这套：

1. 直接把 `github-ready/` 整个目录上传给平台，不要缺 `Dockerfile`、`ctf/`、固件 rootfs 和脚本。
2. 让平台在这个目录根下执行镜像构建，不需要平台宿主机额外装 `tmux`。
3. 题目实例只开放 `37215/tcp`。
4. 真实 flag 通过环境变量 `FLAG_VALUE` 注入。
5. 如果平台支持自定义环境变量，`EXPECTED_CACHE_VALUE` 默认不用改，保持 `HG532_CACHE_OK` 即可。

如果你的平台反而是从 GHCR 拉镜像，再看下面这套：

1. 先确认 GitHub Actions 已经跑完，而且 `Packages` 里确实出现了 `cve2017iot-hg532`。
2. 如果平台支持公开镜像，确认 GHCR package 已设为 public。
3. 如果平台支持私有镜像，给平台配置 GHCR 登录权限，不要匿名拉取私有包。
4. 平台镜像地址优先填 `sha-<提交短哈希>` tag，不要只填 `latest`。
5. 如果平台有镜像缓存或“重置题目不重新拉镜像”的行为，更新题目后要强制重新拉取，不要只看“重置成功”。

如果你的平台既不直接拉 GHCR，也不方便你本地手工打包，那么可以直接从 GitHub Actions 下载：

1. `cve2017iot-hg532-image.tar.gz`
适合平台支持“导入现成镜像 tar”的情况。

2. `cve2017iot-platform-direct.tar.gz`
适合平台支持“上传目录后自行构建 Dockerfile”，并且平台本身能正常拉基础镜像和安装依赖的情况。

一个可直接给平台填写的例子：

```bash
ghcr.io/ziranan/cve2017iot-hg532:sha-7ec87a0
```

如果平台是 GHCR 拉镜像但拉不到，优先排查这几项：

- 填的是不是 `cve2017iot-hg532`，而不是仓库名
- GHCR package 是不是 public
- 平台节点能不能访问 `ghcr.io`
- 平台是不是还在复用旧镜像缓存
- 平台是否只认 tag，不认 digest

## 黑盒测试

本仓库自带的 `exp.py` 现在既能本地测，也能直接测平台地址。

本地容器：

```bash
python3 exp.py --yes
```

远程平台：

```bash
python3 exp.py --host <题目IP> --port 37215 --yes --ready-timeout 120 --flag-timeout 20
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
- 出题平台如果是“上传目录构建”，直接上传整个 `github-ready/` 即可。
- 如果你走 GitHub Actions 分发，也可以直接下载 `hg532-deploy-bundles` 里的两个附件给平台用。
- 出题平台镜像地址不要照仓库名乱填，当前 workflow 推送的是固定包名 `cve2017iot-hg532`。
- 如果部署方平台表现异常，更常见的是平台缓存、平台无法访问 GHCR、或 package 权限问题，不一定是题目镜像本身有问题。
- 如果你本地调试想进 guest，再额外映射 `-p 2222:2222`。
- 如果你手工写 PoC，不要把裸 `&` 直接塞进 `NewDownloadURL`，否则 XML 会坏。
- 旧版本地调试文档里提到的 `tmux attach` 只属于历史调试方式，不再是当前平台运行前提。

## 自定义

运行容器时可以覆盖：

- `FLAG_VALUE`
- `EXPECTED_CACHE_VALUE`
- `SESSION_DIR`
