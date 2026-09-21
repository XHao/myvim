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
  if go install golang.org/x/tools/gopls@latest; then
    # go install 装到 $GOPATH/bin(默认 ~/go/bin),多数 shell 默认不在 PATH 中
    # symlink 到 /opt/homebrew/bin(brew 用户 PATH 必经路径),免手动改 shell 配置
    GO_BIN="$(go env GOPATH)/bin"
    if [ -d "$GO_BIN" ] && [ -w /opt/homebrew/bin ]; then
      ln -sf "$GO_BIN/gopls" /opt/homebrew/bin/gopls 2>/dev/null || true
    fi
    have gopls && ok "gopls 安装完成" || warn "gopls 已装到 $GO_BIN 但不在 PATH → 加 export PATH=\"$HOME/go/bin:\$PATH\" 到 ~/.zshrc"
  else
    warn "gopls 安装失败 → 检查 proxy.golang.org 可达性或切 VPN"
  fi
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

# lombok jar（jdtls 的 javaagent，.vimrc 引用 ~/.vim/lombok.jar，已被 .gitignore 忽略）
install_lombok() {
  local ver=1.18.48
  [ -s "$HOME/.vim/lombok.jar" ] && { ok "lombok ($ver) 已就位，跳过"; return 0; }
  info "下载 lombok $ver (jdtls javaagent, 走 Maven Central)..."
  # 先下 .part 再 mv，避免半截文件让下次幂等检查误判已装
  curl -fsSL "https://repo1.maven.org/maven2/org/projectlombok/lombok/$ver/lombok-$ver.jar" \
    -o "$HOME/.vim/lombok.jar.part" \
    && mv "$HOME/.vim/lombok.jar.part" "$HOME/.vim/lombok.jar" \
    && ok "lombok 安装完成" \
    || { rm -f "$HOME/.vim/lombok.jar.part"; warn "lombok 下载失败 → 检查 repo1.maven.org 可达性"; }
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
install_lombok
install_clang_format
install_black
install_google_java_format
install_prettier

ok "make coding 完成：LSP servers + 格式化器已就位"
