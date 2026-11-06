#!/bin/bash
# Check whether Hermes custom patches are still applied.
# Used by cron watchdog: empty stdout = all patches intact (silent);
# non-empty stdout = something lost (alert delivered).
#
# BASE auto-detects the install directory; override with BASE=/path if needed.
# (Hermes moved from /usr/local/lib/hermes-agent to ~/.hermes/hermes-agent,
#  which made the old hard-coded default report every patch as missing.)
if [ -z "${BASE:-}" ]; then
    if [ -d "$HOME/.hermes/hermes-agent" ]; then
        BASE="$HOME/.hermes/hermes-agent"
    else
        BASE="/usr/local/lib/hermes-agent"
    fi
fi
PATCH_DIR=${PATCH_DIR:-$HOME/.hermes/patches}
ALERT=""

# 1. feishu-reply_to_mode.patch — marker: _normalize_reply_to_mode in feishu adapter
if ! grep -q "_normalize_reply_to_mode" "$BASE/plugins/platforms/feishu/adapter.py" 2>/dev/null; then
    ALERT="${ALERT}⚠️ feishu-reply_to_mode 补丁已丢失（plugins/platforms/feishu/adapter.py 部分）\n"
fi

# 2. auto-reply-filter.patch — markers: _AUTO_REPLY_PREFIXES in gateway/run.py,
#    plus the filter blocks in run_inbound.py (cold path) and run_busy.py (busy path).
if ! grep -q "_AUTO_REPLY_PREFIXES" "$BASE/gateway/run.py" 2>/dev/null; then
    ALERT="${ALERT}⚠️ auto-reply-filter 补丁已丢失（gateway/run.py _AUTO_REPLY_PREFIXES 部分）\n"
elif ! grep -q "_ignore_auto_reply_filter" "$BASE/gateway/run_inbound.py" 2>/dev/null; then
    ALERT="${ALERT}⚠️ auto-reply-filter 补丁已丢失（gateway/run_inbound.py 冷路径部分）\n"
elif ! grep -q "_ignore_auto_reply_filter" "$BASE/gateway/run_busy.py" 2>/dev/null; then
    ALERT="${ALERT}⚠️ auto-reply-filter 补丁已丢失（gateway/run_busy.py 忙路径部分）\n"
fi

# 3. fallback-notify.patch — 已删除（2026-11-07）：本机无 fallback chain，无触发场景。

# [已退役删除 2026-11-07] lifecycle-guard-nul-byte.patch
#   用户判断触发概率过低、维护成本高于收益，已彻底删除（含本脚本检测块）。
# [已过时移除 2026-08-28 v0.20.6] state-db-durability.patch:
#   上游将同步级别改为 config 化 database.synchronous (EXTRA), 不再需要硬编码 patch。
#   替代: hermes config set database.synchronous EXTRA (config.yaml database 段)。
# [已过时移除 2026-08-28 v0.20.6] async-delegation-journal-mode.patch:
#   上游已内化 (_initialize_schema 改用 apply_durability_barriers), 见 tools/async_delegation.py。

if [ -n "$ALERT" ]; then
    echo -e "⚠️ 检测到 Hermes 自定义补丁被覆盖，需要重新应用：\n${ALERT}\n重打命令：cd $BASE && git apply $PATCH_DIR/feishu-reply_to_mode.patch 2>/dev/null; git apply $PATCH_DIR/auto-reply-filter.patch 2>/dev/null"
fi
