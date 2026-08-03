#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

# 可选外部依赖自动安装：fzf / ripgrep / instant-markdown-d
# 均为可选能力：包管理器缺失或安装失败只 WARN 不中断，make verify 兜底提示

PKG_MGR=""
if have brew; then
  PKG_MGR="brew"
elif have apt-get; then
  PKG_MGR="apt"
fi

install_pkg() {
  # $1 命令名  $2 brew 包名  $3 apt 包名
  local cmd="$1" brew_pkg="$2" apt_pkg="$3"
  if have "$cmd"; then
    ok "$cmd 已安装，跳过"
    return 0
  fi
  case "$PKG_MGR" in
    brew)
      if brew install "$brew_pkg"; then
        ok "$cmd 安装完成"
      else
        warn "$cmd 安装失败 → brew install $brew_pkg"
      fi
      ;;
    apt)
      local SUDO=""
      [ "$(id -u)" -ne 0 ] && SUDO="sudo"
      if $SUDO apt-get install -y "$apt_pkg"; then
        ok "$cmd 安装完成"
      else
        warn "$cmd 安装失败 → sudo apt-get install $apt_pkg"
      fi
      ;;
    *)
      warn "$cmd 缺失且无可用包管理器（brew/apt-get），请手动安装"
      ;;
  esac
}

install_pkg fzf fzf fzf
install_pkg rg ripgrep ripgrep

if have instant-markdown-d; then
  ok "instant-markdown-d 已安装，跳过"
elif have npm; then
  if npm -g install instant-markdown-d; then
    ok "instant-markdown-d 安装完成"
  else
    warn "instant-markdown-d 安装失败 → npm -g install instant-markdown-d"
  fi
else
  warn "无 npm，跳过 instant-markdown-d（markdown 预览不可用）→ brew install node"
fi
