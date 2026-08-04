#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

# 前置：vim-lsp 插件已 clone
[ -d "$HOME/.vim/plugged/vim-lsp" ] || {
  err "vim-lsp 插件未克隆，先运行 make install 或 make plugins"
  exit 1
}

# 必需命令（node/npm 走 npm registry，go 走 proxy.golang.org）
require_cmd vim "brew install vim"
require_cmd node "brew install node"
require_cmd npm "brew install node"
require_cmd go "https://go.dev/dl/"

# clangd（系统自带，仅提示）
if have clangd; then
  ok "clangd (C++ LSP) 已就位"
else
  warn "clangd 未找到 → xcode-select --install"
fi

# LSP servers（每个幂等：已装则跳过；失败仅 WARN 不中断）
install_pyright() {
  have pyright && { ok "pyright 已安装，跳过"; return 0; }
  info "装 pyright (Python LSP, 走 npm registry)..."
  npm install -g pyright && ok "pyright 安装完成" || warn "pyright 安装失败 → npm install -g pyright"
}

install_gopls() {
  have gopls && { ok "gopls 已安装，跳过"; return 0; }
  info "装 gopls (Go LSP, 走 proxy.golang.org)..."
  go install golang.org/x/tools/gopls@latest && ok "gopls 安装完成" || warn "gopls 安装失败 → 检查 proxy.golang.org 可达性或切 VPN"
}

install_jdtls() {
  have jdtls && { ok "jdtls 已安装，跳过"; return 0; }
  if ! have brew; then
    warn "brew 未装，jdtls 跳过 (Java LSP) → install Homebrew"
    return 0
  fi
  info "装 jdtls (Java LSP, brew bottle / ghcr.io)..."
  brew install jdtls && ok "jdtls 安装完成" || warn "jdtls 安装失败 → brew install jdtls"
}

# 格式化器
install_clang_format() {
  have clang-format && { ok "clang-format 已安装，跳过"; return 0; }
  info "装 clang-format (C/C++/JS 格式化器)..."
  brew install clang-format && ok "clang-format 安装完成" || warn "clang-format 安装失败 → brew install clang-format"
}

install_black() {
  have black && { ok "black 已安装，跳过"; return 0; }
  brew install black && ok "black 安装完成" || warn "black 安装失败 → brew install black"
}

install_google_java_format() {
  have google-java-format && { ok "google-java-format 已安装，跳过"; return 0; }
  brew install google-java-format && ok "google-java-format 安装完成" || warn "google-java-format 安装失败"
}

install_prettier() {
  have prettier && { ok "prettier 已安装，跳过"; return 0; }
  npm install -g prettier && ok "prettier 安装完成" || warn "prettier 安装失败"
}

# 执行
install_pyright
install_gopls
install_jdtls
install_clang_format
install_black
install_google_java_format
install_prettier

ok "make coding 完成：LSP servers + 格式化器已就位"
