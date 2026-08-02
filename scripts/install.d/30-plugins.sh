#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

require_cmd vim "brew install vim"

info "无头模式安装 Vundle 插件..."
vim -E -s -c "source $HOME/.vimrc" -c "PluginInstall" -c "qa" </dev/null
ok "插件安装完成"
