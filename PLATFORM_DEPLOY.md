# HG532 平台部署说明

这份说明只面向出题平台部署，不讨论你本地 Windows、WSL 或 Docker Desktop 的个别问题。

默认假设：你的平台是“上传目录后，平台自己构建 Dockerfile 并运行容器”。

## 1. 平台直接构建时怎么传

最稳的方式不是 GHCR，而是直接上传 `github-ready/` 整个目录。

要点：

- 上传时不要拆目录，`Dockerfile` 必须在上传包根目录。
- `ctf/`、`_HG532eV100R001C01B020_upgrade_packet.bin.extracted/`、各个启动脚本都要一起上传。
- 平台只需要会构建 Dockerfile，不需要宿主机额外装 `tmux`。

平台开放端口只需要一个：

```text
37215/tcp
```

平台环境变量至少建议填：

```text
FLAG_VALUE=<你的真实 flag>
```

可选：

```text
EXPECTED_CACHE_VALUE=HG532_CACHE_OK
```

## 2. 平台不需要准备什么

- 不需要在平台宿主机额外安装 `tmux`
- 不需要在平台宿主机手工执行 `boot_router.sh`
- 不需要开放 `2222`

当前仓库默认就是按“平台只负责构建 Dockerfile 并启动容器”来准备的。

## 3. 平台最容易出错的地方

如果平台是“上传目录构建”，但题还是起不来，优先排查下面几项：

1. 上传包不完整，少了 `ctf/` 或固件 rootfs 目录。
2. 平台构建上下文不是 `github-ready/` 根目录，导致 `Dockerfile` 找不到文件。
3. 平台没把 `37215` 暴露出来。
4. 平台健康检查太激进，题目还在启动就被判死。
5. 平台“重置题目”只重启容器，没有重新构建。

## 4. 平台部署后怎么验题

题目起来以后，直接从你本地黑盒打：

```bash
python3 exp.py --host <题目IP> --port 37215 --yes --ready-timeout 120 --flag-timeout 20
```

默认会执行：

```sh
echo HG532_CACHE_OK >/tmp/ctf.cache;/bin/check_cache.sh >/tmp/flag_out
```

如果平台部署正常，利用成功后会直接回显 flag。

## 5. 如果你的平台只能吃预构建镜像

这时才考虑 GHCR。

镜像地址不要填仓库名，填 workflow 实际推送出来的包名：

```bash
ghcr.io/<你的 GitHub 用户名>/cve2017iot-hg532:sha-<提交短哈希>
```

优先用 `sha-<提交短哈希>`，不要长期依赖 `latest`。

如果是 GitHub Actions 阶段就已经失败，先看工作流上传的 `hg532-smoke-logs`，不要只盯着红叉。

## 6. 如果平台显示容器启动了，但题还是不通

这时候优先怀疑的是平台侧，不是题目 Dockerfile 本身：

- 平台健康检查太早，把还在启动中的题提前判死
- 平台没有真正把 `37215` 暴露到外部
- 平台做了七层代理或 HTTP 检测，干扰了原始流量
- 平台“重置题目”只是重启容器，没有重新构建或重拉镜像

最稳的核对方式，是在平台节点上直接对外访问：

```bash
curl -i http://127.0.0.1:37215/ctrlt/DeviceUpgrade_1
```

只要这个接口能返回 HTTP 响应，再用 `exp.py` 打就行。
