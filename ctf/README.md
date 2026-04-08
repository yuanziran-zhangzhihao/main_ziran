# Guest Assets

- 诊断配置：`/etc/diag.profile`
- 校验 token：`/etc/diag.token`
- 校验脚本：`/bin/check_cache.sh`
- 校验缓存：`/tmp/ctf.cache`
- 默认期望值：`HG532_CACHE_OK`
- 默认诊断配置占位值：`FLAG{change_me_at_runtime}`

公开仓库时不要把真实 flag 直接写进仓库，部署容器时通过环境变量 `FLAG_VALUE` 注入。
