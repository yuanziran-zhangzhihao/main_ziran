# quickjs-uaf-baby

附件内容：

- `qjs`: 带题目补丁的 QuickJS 二进制
- `quickjs-libc.c.patched`: 题目补丁位置
- `quickjs-uaf-baby.tar.gz`: 题目源码包

题目环境里会自动暴露一个全局对象 `uaf`，可用方法：

- `uaf.help()`
- `uaf.prepare()`
- `uaf.plant()`
- `uaf.read(n)`
- `uaf.status()`
- `uaf.reset()`

如果是本地调试：

```bash
./qjs
```

如果是远程环境：

- 服务会执行你发过去的一份 JavaScript 脚本
- 发送完脚本后关闭连接，等待输出

示例：

```bash
cat exploit.js | nc <host> <port>
```
