#!/bin/bash
# Check whether Hermes custom patches are still applied.
# Used by cron watchdog: empty stdout = all patches intact (silent);
# non-empty stdout = something lost (alert delivered).
BASE=${BASE:-/usr/local/lib/hermes-agent}
PATCH_DIR=${PATCH_DIR:-/root/.hermes/patches}
ALERT=""

# 1. feishu-reply_to_mode.patch — marker: _normalize_reply_to_mode in feishu adapter
if ! grep -q "_normalize_reply_to_mode" "$BASE/plugins/platforms/feishu/adapter.py" 2>/dev/null; then
    ALERT="${ALERT}⚠️ feishu-reply_to_mode 补丁已丢失（plugins/platforms/feishu/adapter.py 部分）\n"
fi

# 2. fallback-notify.patch — marker in chat_completion_helpers.py
if ! grep -q "running as a FALLBACK model" "$BASE/agent/chat_completion_helpers.py" 2>/dev/null; then
    ALERT="${ALERT}⚠️ fallback-notify 补丁已丢失（agent/chat_completion_helpers.py 部分）\n"
fi

# 4. lifecycle-guard-nul-byte.patch.
#    Upstream partially built-in NUL-byte guards (#76762) inside
#    _expand_candidate_path, and 2026-08-24 refactor (#93503) centralized
#    executable-name extraction into _executable_name(). Local patch still
#    needed: try/except on Path() inside _executable_name (guards ALL
#    callers) + _mask_data_sink_arguments uses _executable_name.
if ! grep -q "Patched by eolyn: wrap in try/except (OSError, ValueError)" "$BASE/cron/lifecycle_guard.py" 2>/dev/null; then
    ALERT="${ALERT}⚠️ lifecycle-guard-nul-byte 补丁已丢失（cron/lifecycle_guard.py _executable_name 部分）\n"
elif ! grep -q "_executable_name(segment\[index\]) in _DATA_SINK_EXECUTABLES" "$BASE/cron/lifecycle_guard.py" 2>/dev/null; then
    ALERT="${ALERT}⚠️ lifecycle-guard-nul-byte 补丁已丢失（cron/lifecycle_guard.py _mask_data_sink_arguments 部分）\n"
fi

# 5. auto-reply-filter.patch — marker: _AUTO_REPLY_PREFIXES in gateway/run.py
if ! grep -q "_AUTO_REPLY_PREFIXES" "$BASE/gateway/run.py" 2>/dev/null; then
    ALERT="${ALERT}⚠️ auto-reply-filter 补丁已丢失（gateway/run.py _AUTO_REPLY_PREFIXES 部分）\n"
fi

# [已过时移除 2026-08-28 v0.20.6] state-db-durability.patch:
#   上游将同步级别改为 config 化 database.synchronous (EXTRA), 不再需要硬编码 patch。
#   替代: hermes config set database.synchronous EXTRA (config.yaml database 段)。
# [已过时移除 2026-08-28 v0.20.6] async-delegation-journal-mode.patch:
#   上游已内化 (_initialize_schema 改用 apply_durability_barriers), 见 tools/async_delegation.py。

if [ -n "$ALERT" ]; then
    echo -e "⚠️ 检测到 Hermes 自定义补丁被覆盖，需要重新应用：\n${ALERT}\n重打命令：cd $BASE && git stash pop 2>/dev/null; git apply $PATCH_DIR/feishu-reply_to_mode.patch 2>/dev/null; git apply $PATCH_DIR/fallback-notify.patch 2>/dev/null; git apply $PATCH_DIR/lifecycle-guard-nul-byte.patch 2>/dev/null; git apply $PATCH_DIR/auto-reply-filter.patch 2>/dev/null"
fi