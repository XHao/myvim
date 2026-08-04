#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

YCM_DIR="$HOME/.vim/bundle/YouCompleteMe"

# 探测契约：无 python3 时 cquit 以非 0 退出；有 python3 时跳过 cquit，qa 正常退出 0
if ! vim -E -s -c "if !has('python3') | cquit | endif" -c "qa" </dev/null >/dev/null 2>&1; then
  err "vim 无 python3 支持，无法编译/使用 YCM → brew install vim"
  exit 1
fi

if [ ! -d "$YCM_DIR" ]; then
  info "YCM 未安装，先运行插件安装..."
  bash "$(dirname "$0")/30-plugins.sh"
fi

if [ ! -d "$YCM_DIR/third_party/ycmd" ]; then
  err "YCM 克隆不完整（缺 third_party/ycmd），请重试 make plugins"
  exit 1
fi

if compgen -G "$YCM_DIR/third_party/ycmd/ycm_core*" >/dev/null; then
  ok "YCM 已编译，跳过"
  exit 0
fi

require_cmd python3 "brew install python"
require_cmd cmake "brew install cmake"

info "编译 YouCompleteMe（可能需要几分钟）..."
(cd "$YCM_DIR" && ./install.py --clangd-completer)
ok "YCM 编译完成"
