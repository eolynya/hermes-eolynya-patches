# hermes-eolynya-patches

风澪（Eolyn）针对 Hermes Agent 源码的自定义补丁集。

针对 `/usr/local/lib/hermes-agent` 的手工补丁。`hermes update` 后会被覆盖，需重新应用。

## 补丁列表

| 补丁 | 作用 | 改动文件 |
|------|------|----------|
| `feishu-reply_to_mode.patch` | 飞书适配器支持 `reply_to_mode: off`（回复不引用原消息，直接发独立消息） | `plugins/platforms/feishu/adapter.py` |
| `fallback-notify.patch` | 在系统提示词标注 fallback 状态，让备用模型知道自己正在顶班 | `agent/chat_completion_helpers.py` |
| `lifecycle-guard-nul-byte.patch` | 给 `Path(...).name` 加 try/except（OSError/ValueError），防止 NUL 字节 token 崩溃 lifecycle guard | `cron/lifecycle_guard.py` |
| `auto-reply-filter.patch` | 丢弃以 `[自动回复]`/`自动回复` 开头的入站消息，避免对端自动回复器消耗 agent turn | `gateway/run.py` |

> 注：`cron-napcat-delivery.patch` 已退役（2026-08-12）——napcat 插件（hermes-napcat-plugin）已通过 `register_platform` 声明 `cron_deliver_env_var` + `standalone_sender_fn`，核心不再需要白名单硬编码。

## 应用

```bash
cd /usr/local/lib/hermes-agent
git apply /path/to/feishu-reply_to_mode.patch
git apply /path/to/fallback-notify.patch
git apply /path/to/lifecycle-guard-nul-byte.patch
git apply /path/to/auto-reply-filter.patch
```

## 兼容性

补丁基于 **Hermes Agent v0.20.0（2026.8.3）** 实测验证。补丁是源码级修改，依赖具体代码行；Hermes 版本升级后 `git apply` 可能失败或语义失效，需按新版本代码调整后重新应用。

## 验证

应用后可运行仓库自带的 `check-patches.sh`（marker 检测）确认补丁生效：

```bash
# 默认路径适用于标准安装；如路径不同可显式指定：
#   HERMES_BASE=/usr/local/lib/hermes-agent PATCH_DIR=/root/.hermes/patches bash check-patches.sh
bash check-patches.sh   # 空输出 = 全部补丁完好
```

## 说明

- 补丁由 `check-patches.sh` + cron 每周一 9 点守护检测，`hermes update` 后自动重打。
- 这些是对 Hermes Agent 源码的**非官方修改**，应用后 `hermes update` 会覆盖，且可能与你的其他自定义冲突——风险自负。

## License

[MIT](LICENSE) © 2026 风澪（Eolyn）