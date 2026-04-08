# quickjs-uaf-baby

这是一个面向新手的 QuickJS UAF 题目仓库。

仓库包含两部分：

- 题目服务容器
- 选手附件导出脚本

## 题目接口

- `uaf.help()`
- `uaf.prepare()`
- `uaf.plant()`
- `uaf.read(n)`
- `uaf.status()`
- `uaf.reset()`

## 本地编译

```bash
cd quickjs-2024-01-13
make qjs
```

## 本地验证

```bash
cd quickjs-2024-01-13
./qjs ../solve.js
```

## 服务模式本地测试

启动容器：

```bash
docker build -t quickjs-uaf-baby .
docker run --rm -it -p 9999:9999 -e 'FLAG_VALUE=FLAG{local_test}' quickjs-uaf-baby
```

发送脚本：

```bash
cat solve.js | nc 127.0.0.1 9999
```

服务端会在短暂读空闲后自动开始执行脚本，不依赖客户端额外发送 EOF 半关闭。

## 导出选手附件

```bash
docker build -t quickjs-uaf-baby .
docker run --rm -v "$PWD:/out" --entrypoint /usr/local/bin/export-dist quickjs-uaf-baby /out
```

如果只是本地作者验证，也可以直接导出：

```bash
bash docker/build.sh .
```

## 出题人备注

实际补丁位置在：

- `quickjs-2024-01-13/quickjs-libc.c`

我把 challenge helper 注册到了 `js_std_add_helpers()` 里，所以无论本地执行还是容器内服务执行，脚本都能直接访问全局 `uaf` 对象。
