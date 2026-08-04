# make coding 设计

日期：2026-08-04
状态：已确认（用户批准全 LSP 架构 + LSP servers + 格式化器 + vim-lsp + vim-go）

## 目标

新增 `make coding` 目标，安装开发语言工具链（LSP servers + 格式化器），让 vim 在 C++/Python/Go/Java 上具备现代 IDE 能力（补全、跳转、悬停、code action、重命名、诊断、格式化）。

`make coding` **不**进入 `make install` 主流程，保持两层职责分离：
- `make install`：vim 本身配置就绪（含所有插件 clone）
- `make coding`：开发环境就绪（LSP servers + 格式化器系统二进制）

## 背景

原配置使用 YouCompleteMe（YCM），编译时通过 CMake FetchContent 从 `github.com/abseil/abseil-cpp` 拉取依赖，本机网络对 github.com 不稳定导致 75s 超时失败。

LSP 架构相对优势：
- clangd（C++）：系统自带（Xcode CLT），无 github 依赖
- pyright（Python）：走 npmjs.com，无 github 依赖
- gopls（Go）：走 proxy.golang.org，无 github 依赖
- jdtls（Java）：走 brew bottle / ghcr.io，仅依赖 ghcr.io（与 brew install cmake 同源，曾有过 HTTP/2 协议错但可重试成功）
- vim-lsp / vim-go 插件：依赖 github.com（vim-plug clone），但比 YCM submodule + FetchContent 轻得多

技术优势：Python（pyright 含类型检查，jedi 无）、C++（vim-lsp + clangd 直连，比 YCM 包装版多 hover/code-action/inlay-hints）。

## 架构

```
make install  ──>  vim 配置 + 所有插件（含新增 vim-lsp, vim-go）
                   （已有，无需改 install 链路；.vimrc 新增 Plug 声明后下次 PlugInstall --sync 会拉新插件）

make coding   ──>  LSP servers + 格式化器（系统二进制）
                   前置：make install（确保 vim-lsp 已 clone）

make verify   ──>  扩展检查 LSP 命令 + 二进制存在性

make ycm      ──>  删除（YCM 不再使用）
```

## 组件改动

### 1. .vimrc

**删除：**
- YCM/YCM-Generator 两个 `Plug` 声明（保留 ultisnips, vim-snippets 在 `if has('python3')` 守卫内）
- 全部 `g:ycm_*` 配置（约第 122-139 行）
- YCM 键绑定 `<leader>jd / jc / ji`（约第 202-204 行）
- `let g:ycm_global_ycm_extra_conf = ...` 行

**新增（在 plug#begin 块内）：**
- `Plug 'prabirshrestha/vim-lsp'`
- `Plug 'prabirshrestha/asyncomplete.vim'`（completion popup 集成 vim-lsp，必需）
- `Plug 'fatih/vim-go', { 'for': 'go' }`（懒加载）

**新增（配置 + 键绑定，放在 `plug#end()` 后）：**

```vim
" vim-lsp server 注册
augroup lsp_setup
  autocmd!
  autocmd User lsp_setup call lsp#register_server(#{
    \ name: 'clangd',
    \ cmd: ['clangd', '--background-index', '--clang-tidy'],
    \ allowlist: ['c', 'cpp', 'objc', 'objcpp']})

  autocmd User lsp_setup call lsp#register_server(#{
    \ name: 'pyright',
    \ cmd: ['pyright-langserver', '--stdio'],
    \ allowlist: ['python']})

  autocmd User lsp_setup call lsp#register_server(#{
    \ name: 'gopls',
    \ cmd: ['gopls', 'serve'],
    \ allowlist: ['go', 'gomod', 'gowork']})

  autocmd User lsp_setup call lsp#register_server(#{
    \ name: 'jdtls',
    \ cmd: ['jdtls'],
    \ allowlist: ['java']})
augroup END

" vim-go 配置（与 vim-lp 协作，gopls 作 LSP 来源）
let g:go_def_mode = 'gopls'
let g:go_gopls_enabled = 1

" LSP 通用键绑定（替代旧 YCM 的 <leader>jd/jc/ji）
nnoremap <leader>jd  :LspDefinition<CR>
nnoremap <leader>jc  :LspDeclaration<CR>
nnoremap <leader>ji  :LspImplementation<CR>
nnoremap <leader>jr  :LspReferences<CR>
nnoremap <leader>ca  :LspCodeAction<CR>
nnoremap <leader>rn  :LspRename<CR>
nnoremap K           :LspHover<CR>
nnoremap [d          :LspPreviousDiagnostic<CR>
nnoremap ]d          :LspNextDiagnostic<CR>
nnoremap <leader>dl  :LspDocumentSymbol<CR>
nnoremap <leader>wl  :LspWorkspaceSymbol<CR>

" 保存时格式化（vim-lsp 内置 sync format）
let g:lsp_format_sync_timeout = 1000
```

**保留**：UltiSnips + vim-snippets（与 YCM 解耦，独立工作）；vim-codefmt + `:AutoFormatBuffer clang-format`（C++/JS/proto，与 vim-lsp 的 format 功能平行，codefmt 仍由用户手动 `:AutoFormatBuffer` 触发）。

### 2. Makefile

- `.PHONY` 行：删除 `ycm`，新增 `coding`
- 删除 `ycm:` 目标整段
- 新增：
  ```makefile
  coding: plugins
  	bash $(INSTALL_DIR)/60-coding.sh
  ```
  依赖 `plugins` 确保 vim-lsp 插件已 clone（`60-coding.sh` 内会再次校验 `~/.vim/plugged/vim-lsp` 存在）。

### 3. install scripts

**删除** `scripts/install.d/50-ycm.sh`（YCM 编译逻辑从此废弃）。

**新增** `scripts/install.d/60-coding.sh`：

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

# 前置：vim-lsp 已 clone
[ -d "$HOME/.vim/plugged/vim-lsp" ] || {
  err "vim-lsp 插件未克隆，先运行 make install 或 make plugins"
  exit 1
}

# 必需命令
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

# LSP servers（每个幂等：已装则跳过）
install_pyright() {
  have pyright && { ok "pyright 已安装，跳过"; return 0; }
  info "装 pyright (Python LSP, 走 npm registry)..."
  npm install -g pyright
  ok "pyright 安装完成"
}

install_gopls() {
  have gopls && { ok "gopls 已安装，跳过"; return 0; }
  info "装 gopls (Go LSP, 走 proxy.golang.org)..."
  go install golang.org/x/tools/gopls@latest
  ok "gopls 安装完成"
}

install_jdtls() {
  have jdtls && { ok "jdtls 已安装，跳过"; return 0; }
  if ! have brew; then
    warn "brew 未装，jdtls 跳过 (Java LSP) → install Homebrew"
    return 0
  fi
  info "装 jdtls (Java LSP, brew bottle / ghcr.io)..."
  brew install jdtls
  ok "jdtls 安装完成"
}

# 格式化器
install_clang_format() {
  have clang-format && { ok "clang-format 已安装，跳过"; return 0; }
  info "装 clang-format (C/C++/JS 格式化器)..."
  brew install clang-format
  ok "clang-format 安装完成"
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

# 执行（顺序，便于看进度；总耗时 ~2-5 分钟）
install_pyright
install_gopls
install_jdtls
install_clang_format
install_black
install_google_java_format
install_prettier

ok "make coding 完成：LSP servers + 格式化器已就位"
```

### 4. verify 脚本

**`scripts/verify.sh`** 新增（全部 WARN 级，缺失不阻塞 install）：

```bash
check_bin clangd              "xcode-select --install"   WARN
check_bin pyright             "make coding"             WARN
check_bin gopls               "make coding"             WARN
check_bin jdtls               "make coding"             WARN
check_bin clang-format       "make coding"             WARN
check_bin black              "make coding"             WARN
check_bin google-java-format "make coding"             WARN
check_bin prettier           "make coding"             WARN
```

**`scripts/verify.vim`**：
- 删除 YCM 检查（`ycm_core` glob 探测段）
- 新增 LSP 命令检查：

```vim
call s:check_cmd('LspDefinition',  'vim-lsp 未加载?')
call s:check_cmd('LspCodeAction',  'vim-lsp 未加载?')
call s:check_cmd('LspHover',       'vim-lsp 未加载?')
call s:check_cmd('GoBuild',        'vim-go 未加载?')
call s:check_cmd('GoTest',         'vim-go 未加载?')
```

- 删除 `:PlugInstall` 检查（保留，仍需）

### 5. README.md

- 删除 `### [YouCompleteMe]` 整段
- 加 `### LSP servers (vim-lsp + pyright/gopls/jdtls/clangd)` 新段，描述：
  - 各 server 来源
  - `make coding` 一键安装
  - 手动装等价命令
- 目标表新增 `make coding` 行：
  ```
  | `make coding` | 安装 LSP servers + 格式化器（pyright/gopls/jdtls/clang-format/black/google-java-format/prettier；不进入 make install 主流程） |
  ```
- 删除目标表中 `make ycm` 行
- "已安装插件一览"表：
  - 补全/片段行：删 `YouCompleteMe *, YCM-Generator *`，保留 `ultisnips *, vim-snippets *`
  - 新增行：`LSP/Go 开发 | vim-lsp, asyncomplete, vim-go`

### 6. doc/myvim.txt

- §1 仍为 `vim-plug`
- §2 补全与片段：删 `YouCompleteMe`、`YCM-Generator` 两行，保留 `UltiSnips`、`vim-snippets`
- §3 文件与跳转：键绑定 `<leader>jd/jc/ji` 改为 vim-lsp 版（保留同一快捷键，命令从 `YcmCompleter GoTo...` 改为 `:LspDefinition` 等）
- §6 语言支持：新增 `vim-go` 节（Go 专有命令 `:GoBuild`/`:GoRun`/`:GoTest`/`:GoImport`）
- 新增 §8 LSP（vim-lsp 通用）：
  ```
  8. LSP (vim-lsp)                                              *myvim-lsp*

  clangd              C/C++ LSP（系统自带，无需 make coding）
  pyright             Python LSP（make coding 装，npm registry）
  gopls               Go LSP（make coding 装，proxy.golang.org）
  jdtls               Java LSP（make coding 装，brew bottle）

  通用键绑定：
    <leader>jd        跳转定义 :LspDefinition
    <leader>jc        跳转声明 :LspDeclaration
    <leader>ji        跳转实现 :LspImplementation
    <leader>jr        查找引用 :LspReferences
    <leader>ca        code action :LspCodeAction
    <leader>rn        重命名 :LspRename
    K                 悬停文档 :LspHover
    [d / ]d           上一/下一诊断
    <leader>dl        文档符号 :LspDocumentSymbol
    <leader>wl        工作区符号 :LspWorkspaceSymbol
  ```

## 键绑定映射（旧 → 新）

| 功能 | 旧（YCM） | 新（vim-lsp） |
|---|---|---|
| 跳转定义 | `<leader>jd` → `YcmCompleter GoToDefinition` | `<leader>jd` → `:LspDefinition` |
| 跳转声明 | `<leader>jc` → `YcmCompleter GoToDeclaration` | `<leader>jc` → `:LspDeclaration` |
| 跳转 include | `<leader>ji` → `YcmCompleter GoToInclude` | `<leader>ji` → `:LspImplementation`（语义不同但键位保留） |

新增键绑定（YCM 无）：`<leader>jr` (references)、`<leader>ca` (code action)、`<leader>rn` (rename)、`K` (hover)、`[d`/`]d` (diag nav)。

## 测试策略

### 端到端验证

`make coding` 完成后，`make verify` 应输出：

```
[ OK ] clangd
[ OK ] pyright
[ OK ] gopls
[ OK ] jdtls
[ OK ] clang-format
[ OK ] black
[ OK ] google-java-format
[ OK ] prettier
[PASS] :PlugInstall
[PASS] :LspDefinition
[PASS] :LspCodeAction
[PASS] :LspHover
[PASS] :GoBuild
[PASS] :GoTest
...
```

### 各语言冒烟测试

切 VPN 后跑：

```bash
# C++
echo 'int main(){return 0;}' > /tmp/t.cpp
vim -E -s -c 'source $HOME/.vimrc' -c 'edit /tmp/t.cpp' \
  -c 'redir! > /tmp/lsp.out | LspDefinition | redir END | qa' </dev/null
grep -q 'clangd' /tmp/lsp.out  # 期望 LSP 已 attach

# Python
echo 'x: int = 1' > /tmp/t.py
vim -E -s -c 'source $HOME/.vimrc' -c 'edit /tmp/t.py' \
  -c 'redir! > /tmp/lsp.out | LspHover | redir END | qa' </dev/null
# 期望 pyright 已 attach
```

### 幂等

`make coding` 复跑应显示多个 "已安装，跳过" 且 exit 0。

## 不在范围内

- **Rust**：用户未提；如需可后续追加 `rust-analyzer`（brew 有 bottle）
- **TypeScript/JavaScript LSP**：当前 `.vimrc` 已有 `pangloss/vim-javascript` 做语法高亮，未装 TS server；如需可加 `typescript-language-server`（npm 装包）
- **DAP 调试**：vim-lsp 不含调试；如需调试器另装 `puremourning/vimspector` 或 `mfussenegger/nvim-dap`（后者仅 nvim）
- **vim-go 全功能集成**：本次只装插件，不细配 `:GoMetaLinter` 等（vim-go 默认配置已够用）
- **删除 `~/.vim/.ycm_extra_conf.py`**：YCM 不再用，但该文件作为通用 C++ flags 模板可保留；本次不动

## 回滚

如全 LSP 体验不佳，回滚步骤：

1. `git revert` 本次所有 commit
2. `make install`（恢复 YCM 配置）
3. `PATH=/opt/homebrew/bin:$PATH make ycm`（重新编译 YCM）

由于 YCM 编译受网络限制，回滚需要 VPN 在线。

## 后续工作流

1. 本次实现完成后：用户拉最新 master
2. `make install`（已无需重跑，只新增 vim-lsp/vim-go 插件）
3. `make plugins` 或重启 vim `:PlugInstall`（拉 vim-lsp/vim-go 到 `~/.vim/plugged/`）
4. 切 VPN
5. `PATH=/opt/homebrew/bin:$PATH make coding`（装 LSP servers + 格式化器）
6. `make verify`（确认全 PASS）
