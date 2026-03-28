# Tendora N301 Advisory Challenge

这是一个面向新手的、明显参考老式 Tenda 家用路由器后台体验的合成题。

## 题目定位

这道题不是对真实 Tenda 型号、真实固件、真实历史 CVE 的复现。

它只是在体验层面尽量贴近大家熟悉的老式 SOHO 路由器后台：

- 红白配色的管理页面
- `goform` 风格接口
- Wireless Basic Settings 页面
- 类似公开安全通告的描述方式

这样做的目的，是让新手在不碰真实漏洞复刻的前提下，获得更接近真实路由器题的体验感。

## Advisory Snapshot

- Vendor: Tendora
- Product: N301 Wireless Router
- Firmware: V5.0.1.12_en and earlier
- Affected Component: `POST /goform/WifiBasicSet`
- Vulnerability Type: stack-based buffer overflow
- Attack Prerequisite: access to the web management interface
- Challenge Impact: overwrite an adjacent stack field and enter a hidden diagnostic branch

## 页面和后端风格

前端被设计成一种很典型的老式家用路由器后台：

- 顶部红色品牌栏
- 水平主导航
- 左侧 Wireless 子菜单
- 中间 Wireless Basic Settings 表单
- 右下角 Security Notice / Advisory Snapshot

后端则使用一个非常典型的路由器风格接口：

```text
/goform/WifiBasicSet
```

这让选手一眼就能把它和常见路由器漏洞公告联系起来。

## 漏洞逻辑

后端读取表单中的 `ssid`、`channel`、`password`，真正触发漏洞的是 `ssid`。

服务端的关键栈布局是：

- `ssid_buf[64]`
- `diag_mode[9]`
- `channel_buf[8]`

然后执行：

```c
strcpy(local.ssid_buf, ssid);
```

所以这就是一个非常直白的相邻变量覆盖。

## Intended Solve

只要让 `ssid` 超过 64 字节，并把紧随其后的内容覆盖成：

```text
showflag
```

就能把 `diag_mode` 从 `normal` 改成 `showflag`，后端便会返回隐藏诊断响应和 flag。

新手最短利用思路：

```text
ssid = "A" * 64 + "showflag"
```

## Files

- `routerd.c`: 单文件 C 后端，内嵌前端页面
- `Makefile`: 本地编译
- `run.sh`: 本地启动
- `Dockerfile`: 容器环境
- `solve.py`: 参考脚本

## Local Run

```bash
make
./routerd
```

或者：

```bash
./run.sh
```

然后访问：

```text
http://127.0.0.1:8080/
```

## Reference Solve

```bash
python3 solve.py
```

## Why It Works Well For Beginners

- 页面风格像真实老式路由器后台
- 接口风格像常见 `goform` 提交点
- 漏洞点单一
- 利用链极短
- 不需要 ROP
- 不需要地址泄露
- 不需要复杂调试技巧
