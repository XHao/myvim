#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

require_cmd git "brew install git"
require_cmd vim "brew install vim"

# 提前检测 python3（YCM/UltiSnips 的硬性前提），不满足则提前提示
# 探测契约：无 python3 时 cquit 以非 0 退出；有 python3 时跳过 cquit，qa 正常退出 0
if vim -E -s -c "if !has('python3') | cquit | endif" -c "qa" </dev/null >/dev/null 2>&1; then
  ok "vim 支持 python3"
else
  warn "当前 vim 无 python3 支持，YCM/UltiSnips 将被跳过 → brew install vim"
fi
