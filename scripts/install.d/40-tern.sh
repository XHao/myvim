#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

TERN_DIR="$HOME/.vim/bundle/tern_for_vim"

if [ ! -d "$TERN_DIR" ]; then
  warn "tern_for_vim 未安装，跳过（先运行 make plugins）"
  exit 0
fi

if [ -d "$TERN_DIR/node_modules" ]; then
  ok "tern 依赖已安装，跳过"
  exit 0
fi

if ! have npm; then
  warn "未找到 npm，跳过 tern 依赖安装（brew install node）"
  exit 0
fi

info "安装 tern_for_vim 依赖..."
(cd "$TERN_DIR" && npm install --silent)
ok "tern 依赖安装完成"
