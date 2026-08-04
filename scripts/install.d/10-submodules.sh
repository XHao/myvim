#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

cd "$(dirname "$0")/../.."

require_cmd git "brew install git"

if git submodule status | grep -q '^-'; then
  info "初始化子模块..."
  git submodule update --init
  ok "子模块已就绪"
else
  ok "子模块已是最新，跳过"
fi
