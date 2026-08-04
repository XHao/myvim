# make coding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增 `make coding` 目标安装 LSP servers + 格式化器，把 .vimrc 从 YCM 切换到 vim-lsp + vim-go 全 LSP 架构，删除 `make ycm` 流程。

**Architecture:** 删 YCM/YCM-Generator 声明与配置；.vimrc 加 vim-lsp + asyncomplete + vim-go 声明及 LSP server 注册；Makefile 删 `ycm` target 加 `coding` target；新增 `scripts/install.d/60-coding.sh` 装系统二进制；verify 扩展检查 LSP 命令与二进制；README + myvim.txt 文档同步。

**Tech Stack:** bash、Makefile、vim-plug、vim-lsp、vim-go、clangd/pyright/gopls/jdtls、npm/brew/go install。

**Spec:** `docs/superpowers/specs/2026-08-04-make-coding-design.md`

**全局约定：**
- 所有 bash 脚本以 `#!/usr/bin/env bash` + `set -euo pipefail` 开头
- 脚本幂等（重复运行显示"跳过"）
- Makefile 配方行缩进必须是 Tab
- 本会话 Bash 环境 PATH 中 /usr/bin 在 /opt/homebrew/bin 前，验证命令如需 brew 工具须前缀 `PATH=/opt/homebrew/bin:$PATH`
- 每次修复同步更新本计划文档，保持计划与实现一致
- 当前分支 `feature/make-coding`，spec 已 commit 为 `7661097`

---

### Task 1: .vimrc 切换 YCM → vim-lsp + vim-go

**Files:**
- Modify: `.vimrc`

**Interfaces:**
- Consumes: 现有 .vimrc 第 27-33 行 YCM/UltiSnips 守卫块、第 122-139 行 YCM 配置、第 202-204 行 YCM 键绑定
- Produces: .vimrc 含 vim-lsp/vim-go 声明、LSP server 注册、新键绑定；不含任何 YCM 引用

- [x] **Step 1: 删 YCM Plug 声明（保留 ultisnips/vim-snippets）**

把 .vimrc 第 27-33 行的 YCM 守卫块：

```vim
" ycm + ultisnips（需 vim +python3，否则跳过声明，见 make verify 提示）
if has('python3')
  Plug 'Valloric/YouCompleteMe'
  Plug 'rdnetto/YCM-Generator'
  Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'
endif
```

替换为：

```vim
" ultisnips（需 vim +python3，否则跳过声明）
if has('python3')
  Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'
endif

" vim-lsp + asyncomplete + vim-go（全 LSP 架构，替代 YCM）
Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'fatih/vim-go', { 'for': 'go' }
```

- [x] **Step 2: 删 YCM 配置块**

删 .vimrc 中（约第 121-139 行）从 `"YCM` 注释到 `let g:ycm_seed_identifiers_with_syntax=1` 的整段 YCM 配置。

- [x] **Step 3: 改 YCM extra_conf 路径行**

删 .vimrc 中：
```vim
let g:ycm_global_ycm_extra_conf = '~/.vim/plugged/YouCompleteMe/third_party/ycmd/.ycm_extra_conf.py'
```

- [x] **Step 4: 替换 YCM 键绑定为 LSP 键绑定**

把 .vimrc 中（约第 202-204 行）：

```vim
nnoremap <leader>jc :YcmCompleter GoToDeclaration<CR>
nnoremap <leader>jd :YcmCompleter GoToDefinition<CR>
nnoremap <leader>ji :YcmCompleter GoToInclude<CR>
```

替换为：

```vim
" LSP 通用键绑定（vim-lsp，替代 YCM 的 YcmCompleter）
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
```

- [x] **Step 5: 加 vim-lsp server 注册 + vim-go 配置**

在 `call plug#end()` 后、`filetype plugin indent on` 前，加入：

```vim
" vim-lsp server 注册（各 server 由 make coding 装，clangd 系统自带）
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

" vim-go 配置（与 vim-lsp 协作，gopls 作 LSP 来源）
let g:go_def_mode = 'gopls'
let g:go_gopls_enabled = 1

" 保存时格式化（vim-lp sync format）
let g:lsp_format_sync_timeout = 1000
```

- [x] **Step 6: 验证 .vimrc 无头加载无报错**

Run:
```bash
PATH=/opt/homebrew/bin:$PATH vim -E -s -c 'source $HOME/.vimrc' -c 'verbose echo exists(":LspDefinition")' -c 'qa' </dev/null 2>&1 | tail -3
```
Expected: 输出 `2`（命令存在）；无 E 开头错误。注意：此时 vim-lsp 插件尚未 clone 到 plugged/，命令可能显示 `0`。先验证无 E 级报错。

- [x] **Step 7: 验证全文无 YCM 残留**

Run:
```bash
grep -nE 'YCM|YouCompleteMe|ycm_' /Users/shako/.vim/.vimrc
```
Expected: 无输出（除非 .vimrc 中有注释提及历史 YCM）

- [x] **Step 8: Commit**

```bash
git -C /Users/shako/.vim add .vimrc
git -C /Users/shako/.vim commit -m "Switch .vimrc from YCM to vim-lsp + vim-go"
```

---

### Task 2: Makefile 删 ycm 加 coding

**Files:**
- Modify: `Makefile`

**Interfaces:**
- Consumes: 现有 Makefile 的 `ycm` target 和 `.PHONY` 行
- Produces: Makefile 含 `coding: plugins` target，无 `ycm` target

- [x] **Step 1: 改 .PHONY 行**

把 Makefile 第 1 行：
```makefile
.PHONY: install submodules vimrc plugins help update verify preflight deps ycm
```
改为：
```makefile
.PHONY: install submodules vimrc plugins help update verify preflight deps coding
```

- [x] **Step 2: 删 ycm target**

删 Makefile 中：
```makefile
ycm:
	bash $(INSTALL_DIR)/50-ycm.sh
```

- [x] **Step 3: 加 coding target**

在 `verify:` 块后追加：
```makefile
coding: plugins
	bash $(INSTALL_DIR)/60-coding.sh
```

- [x] **Step 4: 验证 Makefile 语法**

Run:
```bash
make -C /Users/shako/.vim -n coding 2>&1 | tail -3
grep -c 'ycm' /Users/shako/.vim/Makefile; echo "（应为 0）"
```
Expected: `-n coding` 显示 `bash scripts/install.d/60-coding.sh`；grep 计数为 0

- [x] **Step 5: Commit**

```bash
git -C /Users/shako/.vim add Makefile
git -C /Users/shako/.vim commit -m "Replace make ycm with make coding target"
```

---

### Task 3: 删 50-ycm.sh，新增 60-coding.sh

**Files:**
- Remove: `scripts/install.d/50-ycm.sh`
- Create: `scripts/install.d/60-coding.sh`

**Interfaces:**
- Consumes: `scripts/common.sh` 的 `require_cmd` / `have` / `info` / `ok` / `warn` / `err` 函数
- Produces: `60-coding.sh` 装齐 pyright/gopls/jdtls/clang-format/black/google-java-format/prettier（幂等）

- [x] **Step 1: 删 50-ycm.sh**

Run:
```bash
git -C /Users/shako/.vim rm scripts/install.d/50-ycm.sh
```

- [x] **Step 2: 创建 60-coding.sh**

写入 `scripts/install.d/60-coding.sh`：

```bash
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

# 执行
install_pyright
install_gopls
install_jdtls
install_clang_format
install_black
install_google_java_format
install_prettier

ok "make coding 完成：LSP servers + 格式化器已就位"
```

- [x] **Step 3: 给 60-coding.sh 加 +x**

Run:
```bash
chmod +x /Users/shako/.vim/scripts/install.d/60-coding.sh
```

- [x] **Step 4: bash 语法检查**

Run:
```bash
bash -n /Users/shako/.vim/scripts/install.d/60-coding.sh && echo "syntax OK"
```
Expected: `syntax OK`

- [x] **Step 5: Commit**

```bash
git -C /Users/shako/.vim add scripts/install.d/50-ycm.sh scripts/install.d/60-coding.sh
git -C /Users/shako/.vim commit -m "Replace 50-ycm.sh with 60-coding.sh"
```

---

### Task 4: 扩展 verify 脚本

**Files:**
- Modify: `scripts/verify.sh`
- Modify: `scripts/verify.vim`

**Interfaces:**
- Consumes: Task 1 加的 LSP 键绑定命令名、Task 3 装的二进制名
- Produces: `make verify` 报告 LSP 命令与二进制存在性

- [x] **Step 1: verify.sh 新增 LSP/格式化器二进制检查**

在 `scripts/verify.sh` 末尾的 `exit $FAILED` 前加入：

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

- [x] **Step 2: verify.vim 删 YCM 检查、加 LSP 检查**

在 `scripts/verify.vim` 中找到 YCM 检查段（`ycm_core` glob 探测段）：

```vim
if empty(glob(expand('~/.vim/plugged/YouCompleteMe/third_party/ycmd/ycm_core*')))
  call s:report('WARN', 'YCM 未编译', 'cd ~/.vim/plugged/YouCompleteMe && ./install.py --clangd-completer')
else
  call s:report('PASS', 'YCM 已编译', '')
endif
```

整段删除。

在 `call s:check_cmd('PlugInstall', ...)` 后新增：

```vim
call s:check_cmd('LspDefinition',  'vim-lsp 未加载?')
call s:check_cmd('LspCodeAction',  'vim-lsp 未加载?')
call s:check_cmd('LspHover',       'vim-lsp 未加载?')
call s:check_cmd('GoBuild',        'vim-go 未加载?')
call s:check_cmd('GoTest',         'vim-go 未加载?')
```

- [x] **Step 3: 验证 verify.sh 语法**

Run:
```bash
bash -n /Users/shako/.vim/scripts/verify.sh && echo "syntax OK"
```
Expected: `syntax OK`

- [x] **Step 4: 跑 make verify（此时 vim-lsp/vim-go 还没 clone，预期 FAIL 但不应崩溃）**

Run:
```bash
PATH=/opt/homebrew/bin:$PATH make -C /Users/shako/.vim verify 2>&1 | tail -25
```
Expected: `:LspDefinition` / `:GoBuild` 等检查为 `[FAIL]`（vim-lsp/vim-go 未 clone）；二进制检查 `clangd` PASS（系统自带），其余 `[WARN] make coding`（未装）。退出码非 0 但流程跑完。

- [x] **Step 5: Commit**

```bash
git -C /Users/shako/.vim add scripts/verify.sh scripts/verify.vim
git -C /Users/shako/.vim commit -m "Extend verify to check LSP commands and binaries"
```

---

### Task 5: 拉新插件到 plugged/

**Files:** 无（仅触发 PlugInstall）

**Interfaces:**
- Consumes: Task 1 的 .vimrc 改动（新增 vim-lsp / asyncomplete / vim-go 声明）
- Produces: `~/.vim/plugged/{vim-lsp,async.vim,vim-go}/` 目录存在

- [x] **Step 1: 跑 PlugInstall --sync**

Run:
```bash
PATH=/opt/homebrew/bin:$PATH vim -E -s -c 'source $HOME/.vimrc' -c "PlugInstall --sync" -c "qa" </dev/null 2>&1 | tail -10
```
Expected: 无错误输出；vim-lsp / asyncomplete / vim-go 克隆到 plugged/

注：本步需要 github.com 可达（vim-plug 走 github clone）。若用户当前网络不通，可推迟到切 VPN 后再跑。本计划文档保留此步作为后续验证。

- [x] **Step 2: 验证新插件目录存在**

Run:
```bash
ls /Users/shako/.vim/plugged/ | grep -E 'vim-lsp|async|vim-go'
```
Expected: 输出 `async.vim`、`vim-go`、`vim-lsp` 三行

- [x] **Step 3: 跑 make verify，确认 LSP/Go 命令 PASS**

Run:
```bash
PATH=/opt/homebrew/bin:$PATH make -C /Users/shako/.vim verify 2>&1 | grep -E 'LspDef|LspCodeAction|LspHover|GoBuild|GoTest'
```
Expected: 5 行 `[PASS]`

- [x] **Step 4: Commit（无需提交文件，仅记录状态）**

本步不产生代码变更，仅状态变化。无需 commit。若需记录可跳过。

---

### Task 6: 文档同步（README + myvim.txt）

**Files:**
- Modify: `README.md`
- Modify: `doc/myvim.txt`

**Interfaces:**
- Consumes: Task 1-3 的最终状态（无 YCM，新增 vim-lsp/vim-go/make coding）
- Produces: 文档与代码一致

- [x] **Step 1: README.md 删 YCM 段、加 LSP 段**

把 `## plugins` 下的 `### [YouCompleteMe]` 整段（约 14 行）替换为：

```markdown
### LSP servers (vim-lsp + pyright/gopls/jdtls/clangd)

**重要**：`make install` 只克隆 vim 插件到 `~/.vim/plugged/`，**不装** LSP servers 与格式化器。要使用语义补全、跳转、code action 等现代 IDE 能力，必须单独执行：

\```
make coding    # 装 pyright/gopls/jdtls LSP servers + clang-format/black/google-java-format/prettier 格式化器
\```

各组件来源：
- `clangd`（C++）：系统自带（Xcode CLT），无需 make coding
- `pyright`（Python）：npm registry，`npm install -g pyright`
- `gopls`（Go）：proxy.golang.org，`go install golang.org/x/tools/gopls@latest`
- `jdtls`（Java）：brew bottle / ghcr.io，`brew install jdtls`

`make coding` 幂等，已装的组件会跳过。完成后 `make verify` 中相关 `[WARN]` 全部转为 `[PASS]`。

### [vim-instant-markdown](https://github.com/suan/vim-instant-markdown)

需要安装instant-markdown-d：`npm -g install instant-markdown-d`

插件由 vim-plug 安装，自带的 ftplugin 会自动生效，无需额外拷贝文件。
```

注意：保留后面的 "### 从 Vundle 迁移" 段不变。

- [x] **Step 2: README.md 更新 make 目标表**

把目标表中：
```
| `make ycm` | 编译 YouCompleteMe（需 vim +python3，幂等） |
```
替换为：
```
| `make coding` | 安装 LSP servers + 格式化器（pyright/gopls/jdtls/clang-format/black/google-java-format/prettier；不进入 make install 主流程） |
```

- [x] **Step 3: README.md 更新插件一览表**

把"已安装插件一览"小节中：

```
| 补全 / 片段 | YouCompleteMe *, YCM-Generator *, ultisnips *, vim-snippets * |
```

替换为：

```
| 补全 / 片段 | ultisnips *, vim-snippets * |
| LSP / Go 开发 | vim-lsp, asyncomplete.vim, vim-go |
```

并删除该表下方的"带 * 的需 vim +python3"说明中关于 YCM 的部分，改为：

```
带 * 的需 `vim +python3`（macOS 自带 vim 无，须 `brew install vim`）。`.vimrc` 中 `if has('python3')` 守卫会自动跳过未满足的声明，不影响其他插件。带 ⚡ 的按文件类型延迟加载。
```

- [x] **Step 4: doc/myvim.txt §2 删 YCM 节**

把 §2 中：
```
YouCompleteMe       语义补全（需 vim +python3，否则不声明；编译用 make ycm）
  <leader>jd        跳转定义 GoToDefinition
  <leader>jc        跳转声明 GoToDeclaration
  <leader>ji        跳转 include GoToInclude
YCM-Generator       生成 .ycm_extra_conf.py
```
替换为：
```
（YCM 已弃用，改用 vim-lsp，详见 §8）
```

- [x] **Step 5: doc/myvim.txt §3 键绑定改 LSP**

把 §3 中（如有）：
```
  <leader>jd        跳转定义（YCM）
```
改为：
```
  <leader>jd        跳转定义 :LspDefinition（vim-lsp）
  <leader>jc        跳转声明 :LspDeclaration
  <leader>ji        跳转实现 :LspImplementation
  <leader>jr        查找引用 :LspReferences
  <leader>ca        code action :LspCodeAction
  <leader>rn        重命名 :LspRename
  K                 悬停文档 :LspHover
  [d / ]d           上一/下一诊断
```

- [x] **Step 6: doc/myvim.txt §6 加 vim-go 节**

在 §6 语言支持末尾加：
```
vim-go               Go 开发集成（懒加载，编辑 .go 时加载）
  :GoBuild           编译当前包
  :GoRun             运行
  :GoTest            测试
  :GoImport          导入包
  :GoFmt             格式化
  :GoDef             跳转定义（gopls）
```

- [x] **Step 7: doc/myvim.txt 新增 §8 LSP**

在 §7 后追加：

```
==============================================================================
8. LSP (vim-lsp)                                              *myvim-lsp*

vim-lsp            LSP 客户端（替代 YCM，无需编译）

  clangd           C/C++ LSP（系统自带，无需 make coding）
  pyright          Python LSP（make coding 装，npm registry）
  gopls            Go LSP（make coding 装，proxy.golang.org）
  jdtls            Java LSP（make coding 装，brew bottle）

通用键绑定：
  <leader>jd       跳转定义 :LspDefinition
  <leader>jc       跳转声明 :LspDeclaration
  <leader>ji       跳转实现 :LspImplementation
  <leader>jr       查找引用 :LspReferences
  <leader>ca       code action :LspCodeAction
  <leader>rn       重命名 :LspRename
  K                悬停文档 :LspHover
  [d / ]d          上一/下一诊断
  <leader>dl       文档符号 :LspDocumentSymbol
  <leader>wl       工作区符号 :LspWorkspaceSymbol

LSP servers 与格式化器由 `make coding` 安装，详见 README.md。
```

- [x] **Step 8: 验证文档无 YCM 残留（迁移说明段除外）**

Run:
```bash
grep -in 'YCM\|YouCompleteMe\|make ycm' /Users/shako/.vim/README.md /Users/shako/.vim/doc/myvim.txt
```
Expected: 无输出

- [x] **Step 9: 重新生成 doc/tags**

Run:
```bash
PATH=/opt/homebrew/bin:$PATH vim -E -s -c 'helptags $HOME/.vim/doc' -c "qa" </dev/null
ls -la /Users/shako/.vim/doc/tags
```
Expected: doc/tags 比 myvim.txt 新

- [x] **Step 10: Commit**

```bash
git -C /Users/shako/.vim add README.md doc/myvim.txt
git -C /Users/shako/.vim commit -m "Update docs for vim-lsp migration"
```

---

### Task 7: 端到端验证

**Files:** 无（纯验证）

- [x] **Step 1: 重新跑 make install 确保幂等**

Run:
```bash
PATH=/opt/homebrew/bin:$PATH make -C /Users/shako/.vim install 2>&1 | grep -c '跳过\|Already'
echo "exit=$?"
```
Expected: 多个"跳过"；退出码 0

- [x] **Step 2: 跑 make verify 全套检查**

Run:
```bash
PATH=/opt/homebrew/bin:$PATH make -C /Users/shako/.vim verify 2>&1 | tail -30
```
Expected: `:LspDefinition` / `:LspCodeAction` / `:LspHover` / `:GoBuild` / `:GoTest` 全 `[PASS]`；二进制检查中 `clangd` PASS，其余 `[WARN] make coding`（LSP servers 与格式化器未装，待用户切 VPN 后跑 `make coding`）

- [x] **Step 3: 启动 vim 无报错**

Run:
```bash
PATH=/opt/homebrew/bin:$PATH vim -E -s -c 'qa' </dev/null 2>&1 | head -5
echo "exit=$?"
```
Expected: 无错误输出；exit=0

- [x] **Step 4: help myvim 仍可用**

Run:
```bash
PATH=/opt/homebrew/bin:$PATH vim -E -s -c 'redir! > /tmp/h.out' -c 'help myvim' -c 'echo expand("%:t")' -c 'redir END' -c 'qa' </dev/null 2>&1
cat /tmp/h.out | tail -1
rm -f /tmp/h.out
```
Expected: 输出 `myvim.txt`

- [x] **Step 5: 更新本计划文档勾选状态，提交**

```bash
git -C /Users/shako/.vim add docs/superpowers/plans/2026-08-04-make-coding.md
git -C /Users/shako/.vim commit -m "Verify make coding setup end-to-end"
```

---

## 切 VPN 后的执行清单（不在本计划内，仅供用户参考）

用户切 VPN 后执行：

```bash
PATH=/opt/homebrew/bin:$PATH make -C ~/.vim coding    # 装 LSP servers + 格式化器
PATH=/opt/homebrew/bin:$PATH make -C ~/.vim verify    # 全部 PASS
```

如 `make coding` 中 jdtls 拉取失败（ghcr.io 不稳），可单独重试 `brew install jdtls`。
