# quickjs-uaf-baby

这是一个面向新手的 QuickJS UAF 题目。

## 题目思路

我在 QuickJS 的解释器 helper 里额外挂了一个全局对象 `uaf`。

可用接口：

- `uaf.help()`
- `uaf.prepare()`
- `uaf.plant()`
- `uaf.read(n)`
- `uaf.status()`
- `uaf.reset()`

核心漏洞是：

1. `uaf.prepare()` 在 C 层创建一个 QuickJS `ArrayBuffer`
2. 取出它的 backing store 指针
3. 立刻释放这个 `ArrayBuffer`
4. 但代码故意把原来的 data 指针留下来，形成 dangling pointer
5. `uaf.plant()` 再申请一个同样大小的 chunk，并把 flag 写进去
6. 因为 chunk size 一样，glibc tcache 会优先复用刚刚 free 掉的那块内存
7. `uaf.read()` 通过悬挂指针把 flag 读出来

所以本题是一个非常直白的 QuickJS ArrayBuffer backing store UAF。

## 适合新手的原因

- 不需要理解完整的 QuickJS 对象模型
- 不需要 FakeObject / addrof / fakeobj
- 不需要任意地址读写
- 不需要 shellcode 或 ROP
- 利用链固定，现象稳定

## 目录

- `quickjs-2024-01-13/`: 官方 QuickJS 源码，已打补丁
- `solve.js`: 参考解
- `README.md`: 题目说明

## 编译

```bash
cd quickjs-2024-01-13
make qjs
```

## 运行

进入交互环境：

```bash
cd quickjs-2024-01-13
./qjs
```

手动利用：

```javascript
print(uaf.help())
uaf.prepare()
let info = uaf.plant()
print(JSON.stringify(info))
print(uaf.read(0x40))
```

直接跑参考解：

```bash
cd quickjs-2024-01-13
./qjs ../solve.js
```

## 出题人说明

实际补丁位置在：

- `quickjs-2024-01-13/quickjs-libc.c`

我把 challenge helper 注册到了 `js_std_add_helpers()` 里，所以用普通 `qjs` 启动就能直接访问全局 `uaf` 对象。
