# 一键安装与 vim 配置增强 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 ~/.vim 配置仓库改造为 Makefile 驱动的模块化一键安装，并增强插件栈（fzf/fugitive/auto-pairs/gutentags）、提供分层验证（make verify）与内置帮助文档（:help myvim）。

**Architecture:** Makefile 作统一入口，调用 `scripts/install.d/` 下按序编号的 bash 脚本（均 source `scripts/common.sh`）。验证分两层：shell 检查外部依赖（`scripts/verify.sh`）+ 无头 vim 检查插件能力（`scripts/verify.vim`）。设计细节见 `docs/superpowers/specs/2026-08-02-one-click-install-design.md`。

**Tech Stack:** bash、Makefile、Vundle、vim script。

**Spec:** `docs/superpowers/specs/2026-08-02-one-click-install-design.md`

**全局约定：**
- 所有 bash 脚本以 `#!/usr/bin/env bash` + `set -euo pipefail` 开头
- 脚本均可独立运行且幂等（重复运行显示"跳过"）
- Makefile 配方行缩进必须是 Tab，不是空格

---

### Task 1: scripts/common.sh — 公共日志/依赖检查库

**Files:**
- Create: `scripts/common.sh`

- [ ] **Step 1: 创建文件**

```bash
#!/usr/bin/env bash
# 公共函数库：日志、依赖检查。只能被 source，不要直接执行。

if [[ -t 1 ]]; then
  C_INFO='\033[0;34m'; C_OK='\033[0;32m'; C_WARN='\033[0;33m'; C_ERR='\033[0;31m'; C_OFF='\033[0m'
else
  C_INFO=''; C_OK=''; C_WARN=''; C_ERR=''; C_OFF=''
fi

info() { printf "${C_INFO}[INFO]${C_OFF} %s\n" "$*"; }
ok()   { printf "${C_OK}[ OK ]${C_OFF} %s\n" "$*"; }
warn() { printf "${C_WARN}[WARN]${C_OFF} %s\n" "$*"; }
err()  { printf "${C_ERR}[FAIL]${C_OFF} %s\n" "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

require_cmd() {
  if ! have "$1"; then
    err "缺少必需命令: $1 → $2"
    exit 1
  fi
}
```

- [ ] **Step 2: 验证可 source 且函数可用**

Run: `bash -c 'source scripts/common.sh && have git && info "common.sh 加载成功"'`
Expected: 输出 `[INFO] common.sh 加载成功`

- [ ] **Step 3: 验证 require_cmd 对缺失命令报错退出**

Run: `bash -c 'source scripts/common.sh; require_cmd nonexistent-cmd-xyz "test hint"'; echo "exit=$?"`
Expected: 输出含 `[FAIL] 缺少必需命令: nonexistent-cmd-xyz → test hint`，`exit=1`

- [ ] **Step 4: Commit**

```bash
git add scripts/common.sh
git commit -m "Add common.sh with logging and dependency check helpers"
```

---

### Task 2: install.d/10-submodules.sh 与 20-vimrc.sh

**Files:**
- Create: `scripts/install.d/10-submodules.sh`
- Create: `scripts/install.d/20-vimrc.sh`

- [ ] **Step 1: 创建 10-submodules.sh**

```bash
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
```

- [ ] **Step 2: 创建 20-vimrc.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

VIMRC_SRC="$HOME/.vim/.vimrc"
VIMRC_DST="$HOME/.vimrc"

# 已是指向本仓库的软链（含相对软链）→ 幂等跳过
if [ -L "$VIMRC_DST" ]; then
  CURTARGET="$(readlink "$VIMRC_DST")"
  case "$CURTARGET" in
    /*) ;;
    *)  CURTARGET="$(dirname "$VIMRC_DST")/$CURTARGET" ;;
  esac
  CURTARGET="${CURTARGET%/}"
  if [ "$CURTARGET" = "$VIMRC_SRC" ]; then
    ok "~/.vimrc 已链接到本仓库，跳过"
    exit 0
  fi
fi

# 存在其它文件或软链 → 备份后替换
if [ -e "$VIMRC_DST" ] || [ -L "$VIMRC_DST" ]; then
  BACKUP="$VIMRC_DST.bak.$(date +%Y%m%d)"
  n=1
  while [ -e "$BACKUP" ] || [ -L "$BACKUP" ]; do
    BACKUP="$VIMRC_DST.bak.$(date +%Y%m%d).$n"
    n=$((n+1))
  done
  warn "备份已有 ~/.vimrc → $BACKUP"
  mv "$VIMRC_DST" "$BACKUP"
fi

ln -s "$VIMRC_SRC" "$VIMRC_DST"
ok "已创建软链 ~/.vimrc → $VIMRC_SRC"
```

- [ ] **Step 3: 验证 10 幂等（本机子模块已就绪，应显示跳过）**

Run: `bash scripts/install.d/10-submodules.sh`
Expected: `[ OK ] 子模块已是最新，跳过`，退出码 0

- [ ] **Step 4: 验证 20 幂等（本机软链已存在，应显示跳过）**

Run: `bash scripts/install.d/20-vimrc.sh && bash scripts/install.d/20-vimrc.sh`
Expected: 两次均 `[ OK ] ~/.vimrc 已链接到本仓库，跳过`

- [ ] **Step 5: 验证 20 的备份逻辑（模拟已有 vimrc）**

Run:
```bash
mv ~/.vimrc /tmp/vimrc-link-save
echo "test" > ~/.vimrc
bash scripts/install.d/20-vimrc.sh
cat ~/.vimrc.bak.$(date +%Y%m%d)   # 应输出 test
ls -la ~/.vimrc                      # 应是指向 .vim/.vimrc 的软链
```
Expected: 备份文件内容为 `test`，`~/.vimrc` 为软链

- [ ] **Step 6: Commit**

```bash
git add scripts/install.d/10-submodules.sh scripts/install.d/20-vimrc.sh
git commit -m "Add submodule and vimrc install scripts (idempotent)"
```

---

### Task 3: install.d/30-plugins.sh 与 40-tern.sh

**Files:**
- Create: `scripts/install.d/30-plugins.sh`
- Create: `scripts/install.d/40-tern.sh`

- [ ] **Step 1: 创建 30-plugins.sh（无头 PluginInstall）**

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

require_cmd vim "brew install vim"

info "无头模式安装 Vundle 插件..."
# 注意：单个插件克隆失败不会反映到本脚本退出码，由 make verify 兜底检测
vim -E -s -c 'source $HOME/.vimrc' -c "PluginInstall" -c "qa" </dev/null
ok "插件安装完成"
```

- [ ] **Step 2: 创建 40-tern.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

TERN_DIR="$HOME/.vim/bundle/tern_for_vim"

if [ ! -d "$TERN_DIR" ]; then
  warn "tern_for_vim 未安装，跳过（先运行 make plugins）"
  exit 0
fi

if [ -d "$TERN_DIR/node_modules/tern" ]; then
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
```

- [ ] **Step 3: 验证 30（插件已装，应快速完成）**

Run: `bash scripts/install.d/30-plugins.sh; echo "exit=$?"`
Expected: 末尾 `[ OK ] 插件安装完成`，`exit=0`

- [ ] **Step 4: 验证 40（tern 装依赖，二次运行跳过）**

Run: `bash scripts/install.d/40-tern.sh && bash scripts/install.d/40-tern.sh`
Expected: 第一次 `[INFO] 安装 tern_for_vim 依赖...` → `[ OK ]`；第二次 `[ OK ] tern 依赖已安装，跳过`

- [ ] **Step 5: Commit**

```bash
git add scripts/install.d/30-plugins.sh scripts/install.d/40-tern.sh
git commit -m "Add headless plugin install and tern npm scripts"
```

---

### Task 4: Makefile 与 init.sh 兼容入口

**Files:**
- Create: `Makefile`
- Modify: `init.sh`（整体重写）

- [ ] **Step 1: 创建 Makefile（注意：配方行必须用 Tab 缩进）**

```makefile
.PHONY: install submodules vimrc plugins tern help update verify

INSTALL_DIR := scripts/install.d

install: verify
	@echo ""
	@echo "== 安装完成。上方如有 WARN 请按提示处理 =="

submodules:
	bash $(INSTALL_DIR)/10-submodules.sh

vimrc: submodules
	bash $(INSTALL_DIR)/20-vimrc.sh

plugins: vimrc
	bash $(INSTALL_DIR)/30-plugins.sh

tern: plugins
	bash $(INSTALL_DIR)/40-tern.sh

help: tern
	vim -E -s -c 'helptags $$HOME/.vim/doc' -c "qa" </dev/null
	@echo "[ OK ] doc/tags 已生成"

update:
	git submodule update --init
	vim -E -s -c 'source $$HOME/.vimrc' -c "PluginInstall!" -c "qa" </dev/null

verify: help
	bash scripts/verify.sh
	vim -E -s -S scripts/verify.vim </dev/null
```

注意：`verify` 目标引用的 `scripts/verify.sh` / `scripts/verify.vim` 在 Task 7 才创建，本任务内不要运行 `make verify` / `make install`。

- [ ] **Step 2: 重写 init.sh 为兼容入口（经符号链接调用也能解析到真实仓库目录）**

```bash
#!/usr/bin/env bash
# 兼容入口：等价于 make install（可经符号链接调用）
set -euo pipefail

SOURCE="$0"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
cd "$(cd -P "$(dirname "$SOURCE")" && pwd)"
exec make install
```

- [ ] **Step 3: 验证各独立目标**

Run: `make submodules && make vimrc && make plugins && make tern`
Expected: 全部成功，均显示"跳过/已就绪"

- [ ] **Step 4: Commit**

```bash
git add Makefile init.sh
git commit -m "Add Makefile entry points; init.sh now delegates to make install"
```

---

### Task 5: .gitignore 调整 + doc/myvim.txt 帮助文档

**Files:**
- Modify: `.gitignore`（删 `doc/` 行，加 `doc/tags`）
- Create: `doc/myvim.txt`

- [ ] **Step 1: 修改 .gitignore**

删除 `.gitignore` 中的 `doc/` 一行，在末尾追加：

```
doc/tags
```

- [ ] **Step 2: 创建 doc/myvim.txt**

```
*myvim.txt*  myvim 插件能力一览                                    *myvim*

本手册列出 ~/.vim 配置中所有插件的用途、命令与快捷键。
新增插件时请同步维护本文档与 scripts/verify.vim。

==============================================================================
1. 插件管理                                                   *myvim-vundle*

Vundle.vim          插件管理器
  :PluginInstall    安装 .vimrc 中声明的插件
  :PluginInstall!   更新全部插件
  :PluginClean      清理未声明的插件

==============================================================================
2. 补全与片段                                                *myvim-complete*

YouCompleteMe       语义补全（需编译，需 vim +python3）
  <leader>jd        跳转定义 GoToDefinition
  <leader>jc        跳转声明 GoToDeclaration
  <leader>ji        跳转 include GoToInclude
YCM-Generator       生成 .ycm_extra_conf.py
UltiSnips           代码片段引擎（需 python3）
  <leader><tab>     展开片段 / 跳到下一占位符
  <leader><s-tab>   跳到上一占位符
vim-snippets        片段库

==============================================================================
3. 文件与跳转                                              *myvim-navigation*

NERDTree            文件树（<C-n> 开关），显示隐藏文件
nerdtree-git-plugin 文件树中显示 git 状态图标
Tagbar              符号大纲（<C-t> 开关）
fzf + fzf.vim       模糊搜索（需 fzf、ripgrep 二进制）
  <C-p>             :Files 模糊找文件
  <leader>rg        :Rg 全文搜索
vim-fswitch         <leader>swi 在 .cpp/.h 间切换
vim-gutentags       后台自动维护 ctags（缓存于 ~/.cache/tags）

==============================================================================
4. Git                                                          *myvim-git*

vim-fugitive        vim 内 Git
  :Git blame        逐行 blame
  :Git diff         diff
  :Git log          日志

==============================================================================
5. 编辑增强                                                 *myvim-editing*

auto-pairs          括号/引号自动配对（替代旧自研函数）
nerdcommenter       注释开关（<leader>c<space> 切换注释）
tabular             对齐（:Tab /字符）
vim-surround 未装；自动配对由 auto-pairs 负责

==============================================================================
6. 语言支持                                               *myvim-languages*

vim-cpp-enhanced-highlight   C++ 增强高亮
vim-javacomplete2            Java 补全
vim-javascript-syntax        JS 语法高亮
tern_for_vim                 JS 跳转（<leader>d → TernDef，需 npm install）
node                         node 文件类型支持
vim-markdown                 Markdown 高亮/折叠
vim-instant-markdown         浏览器实时预览（需 instant-markdown-d）

==============================================================================
7. 界面与格式化                                                 *myvim-ui*

vim-airline         状态栏 + tabline
vim-indent-guides   缩进参考线（启动即启用，从第 2 级开始）
molokai             配色方案
vim-codefmt         保存时自动格式化（c/cpp/proto/javascript，clang-format）
vim-maktaba/glaive  codefmt 的依赖框架

==============================================================================
 vim:tw=78:ts=8:ft=help:norl:
```

- [ ] **Step 3: 生成 tags 并验证 :help myvim 可用**

Run: `make help && vim -E -s -c "help myvim" -c "qa" </dev/null; echo "exit=$?"`
Expected: `[ OK ] doc/tags 已生成`，`exit=0`

- [ ] **Step 4: 确认 git 状态干净（doc/tags 被忽略、doc/myvim.txt 被跟踪）**

Run: `git status --short`
Expected: 只显示 `.gitignore` 修改和 `doc/myvim.txt` 新增，不出现 `doc/tags`

- [ ] **Step 5: Commit**

```bash
git add .gitignore doc/myvim.txt
git commit -m "Add :help myvim plugin capability doc; un-ignore doc/, ignore doc/tags"
```

---

### Task 6: .vimrc 插件栈调整（增 4 删 3，移除自研配对函数）

**Files:**
- Modify: `.vimrc`

- [ ] **Step 1: 删除 indexer 三件套**

从 .vimrc 删除以下 3 行（约 .vimrc:59-62 区域）：

```vim
" indexer
Plugin 'vim-scripts/indexer.tar.gz'
Plugin 'vim-scripts/DfrankUtil'
Plugin 'vim-scripts/vimprj'
```

- [ ] **Step 2: 新增 4 个插件声明**

在 `Plugin 'scrooloose/nerdcommenter'` 之前插入：

```vim
" fzf 模糊搜索（需 brew install fzf ripgrep）
Plugin 'junegunn/fzf'
Plugin 'junegunn/fzf.vim'
" git
Plugin 'tpope/vim-fugitive'
" 括号自动配对
Plugin 'jiangmiao/auto-pairs'
" 自动维护 ctags
Plugin 'ludovicchabant/vim-gutentags'

```

- [ ] **Step 3: 删除自研括号/引号配对代码**

从 .vimrc 删除以下全部内容（约 .vimrc:213-243）：

```vim
" imap
inoremap ( ()<LEFT>
inoremap [ []<LEFT>
inoremap { {}<LEFT>

inoremap ) <c-r>=ClosePair(')')<CR>
inoremap ] <c-r>=ClosePair(']')<CR>
inoremap } <c-r>=ClosePair('}')<CR>

inoremap " <c-r>=QuoteDelim('"')<CR>
inoremap ' <c-r>=QuoteDelim("'")<CR>

function ClosePair(char)
    if getline('.')[col('.') - 1] == a:char
        return "\<Right>"
    else
        return a:char
    endif
endf

function QuoteDelim(char)
    let line = getline('.')
    let col = col('.')
    if line[col - 2] == "\\"
        return a:char
    elseif line[col - 1] == a:char
        return "\<Right>"
    else
        return a:char.a:char."\<LEFT>"
    endif
endf
```

- [ ] **Step 4: 新增 fzf 与 gutentags 配置**

在 .vimrc 末尾追加：

```vim
" fzf（无二进制时不映射，避免 fzf 插件弹出阻塞式下载提示）
if executable('fzf')
  nnoremap <C-p> :Files<CR>
endif
if executable('rg')
  nnoremap <leader>rg :Rg<CR>
endif

" gutentags（BSD ctags 不支持 --recurse，检测到不兼容则禁用）
let g:gutentags_cache_dir = expand('~/.cache/tags')
let g:gutentags_project_root = ['.git']
call mkdir(g:gutentags_cache_dir, 'p')
if !executable('ctags') || system('ctags --version') !~? 'exuberant\|universal'
  let g:gutentags_enabled = 0
endif
```

- [ ] **Step 5: 安装新插件并清理旧插件**

Run: `make plugins && vim -E -s -c "source $HOME/.vimrc" -c "PluginClean" -c "qa" </dev/null`
Expected: fzf、fzf.vim、vim-fugitive、auto-pairs、vim-gutentags 被克隆；indexer 三件套目录被清理（vim -E 模式下 PluginClean 会自动确认）

- [ ] **Step 6: 验证插件目录**

Run: `ls ~/.vim/bundle/ | grep -E 'fzf|fugitive|auto-pairs|gutentags'; ls ~/.vim/bundle/ | grep -E 'indexer|DfrankUtil|vimprj'; echo "check done"`
Expected: 第一组输出 5 个目录（fzf, fzf.vim, vim-fugitive, auto-pairs, vim-gutentags）；第二组无输出

- [ ] **Step 7: 验证 vim 启动无报错**

Run: `vim -E -s -c "qa" </dev/null 2>&1; echo "exit=$?"`
Expected: 无错误输出，`exit=0`

- [ ] **Step 8: Commit**

```bash
git add .vimrc
git commit -m "Add fzf/fugitive/auto-pairs/gutentags; drop indexer trio and custom pair functions"
```

---

### Task 7: 分层验证 scripts/verify.sh + scripts/verify.vim

**Files:**
- Create: `scripts/verify.sh`
- Create: `scripts/verify.vim`

- [ ] **Step 1: 创建 scripts/verify.sh（外部依赖层）**

```bash
#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "$0")/common.sh"

FAILED=0

check_bin() {
  # $1 命令名  $2 安装提示  $3 级别(WARN/FAIL)
  if have "$1"; then
    ok "$1"
  elif [ "$3" = "FAIL" ]; then
    err "$1 缺失 → $2"
    FAILED=1
  else
    warn "$1 缺失 → $2"
  fi
}

check_bin git    "brew install git"                     FAIL
check_bin vim    "brew install vim"                     FAIL
check_bin fzf    "brew install fzf"                     WARN
check_bin rg     "brew install ripgrep"                 WARN
check_bin ctags  "brew install ctags"                   WARN
check_bin node   "brew install node"                    WARN
check_bin npm    "brew install node"                    WARN
check_bin instant-markdown-d "npm -g install instant-markdown-d" WARN

exit $FAILED
```

- [ ] **Step 2: 创建 scripts/verify.vim（插件能力层）**

> 落地时与原计划有差异，记录于本块注释中。原因：
> 1. `vim -E -s` 既不自动 source vimrc、也不自动 `runtime! plugin/*.vim`，仅 `source $HOME/.vimrc` 时所有插件命令都未注册（全部 FAIL）。
>    → 必须显式追加 `runtime! plugin/**/*.vim`。
> 2. `:GutentagsUpdate` 是 `command! -buffer` 缓冲区局部命令，仅在 `gutentags#setup_gutentags()` 处理真实项目缓冲区时才注册，
>    `-E -s` 无头模式下永远不可全局 `exists()` 命中。改用 `exists('g:gutentags_enabled')` 验证插件已加载。
> 3. `echom` 在 `-s` 静默模式下不会输出到 stdout（只能 `:messages` 查），make 输出里看不到 PASS/WARN。
>    → 累计报告入 `s:lines`，结尾用 `:call writefile()` + `:!cat` 输出到 stdout。

```vim
" 插件能力冒烟测试：由 make verify 以 vim -E -s -S 执行
" 注意：-E -s 模式不会自动加载 vimrc，也不会自动 source plugin/*.vim，
" 必须显式 source vimrc 并 runtime! plugin/**/*.vim 才能让插件命令注册。
" echom 在 -s 模式不会输出到 stdout，所以报告累加进 s:lines，
" 最后用 :!cat 输出到 stdout，并用 :cquit 反映退出码。
" FAIL → :cquit（退出码非 0）；WARN 不阻塞
" 约定：.vimrc 新增插件时在此登记一行检查

source $HOME/.vimrc
runtime! plugin/**/*.vim

let s:fail = 0
let s:lines = []

function! s:report(level, name, hint) abort
  if a:level ==# 'PASS'
    let l:line = '[PASS] ' . a:name
  elseif a:level ==# 'WARN'
    let l:line = '[WARN] ' . a:name . ' → ' . a:hint
  else
    let l:line = '[FAIL] ' . a:name . ' → ' . a:hint
    let s:fail = 1
  endif
  call add(s:lines, l:line)
  " 仍 echom 一份，便于 :messages 调试
  echom l:line
endfunction

function! s:check_cmd(cmd, hint) abort
  if exists(':' . a:cmd) == 2
    call s:report('PASS', ':' . a:cmd, '')
  else
    call s:report('FAIL', ':' . a:cmd, a:hint)
  endif
endfunction

call s:check_cmd('NERDTreeToggle', '运行 make plugins')
call s:check_cmd('TagbarToggle', '运行 make plugins')
call s:check_cmd('Files', 'junegunn/fzf 未装上？运行 make plugins')
call s:check_cmd('Rg', 'fzf.vim 未装上？运行 make plugins')
call s:check_cmd('Git', 'vim-fugitive 未装上？运行 make plugins')
call s:check_cmd('AutoFormatBuffer', 'vim-codefmt 未装上？运行 make plugins')
" GutentagsUpdate 是 buffer-local 命令，仅在打开项目缓冲区时注册，
" 在 -E -s 无头模式下不可用。改为检查插件已加载（g:gutentags_enabled 存在）。
if exists('g:gutentags_enabled')
  call s:report('PASS', 'vim-gutentags 插件已加载', '')
else
  call s:report('FAIL', 'vim-gutentags 插件', '运行 make plugins')
endif

try
  colorscheme molokai
  call s:report('PASS', 'colorscheme molokai', '')
catch
  call s:report('FAIL', 'colorscheme molokai', '检查 colors/molokai.vim 是否存在')
endtry

if has('python3')
  call s:report('PASS', 'vim +python3', '')
else
  call s:report('WARN', 'vim 无 python3，YCM/UltiSnips 不可用', 'brew install vim')
endif

if empty(glob(expand('~/.vim/bundle/YouCompleteMe/third_party/ycmd/ycm_core*')))
  call s:report('WARN', 'YCM 未编译', 'cd ~/.vim/bundle/YouCompleteMe && ./install.py --clangd-completer')
else
  call s:report('PASS', 'YCM 已编译', '')
endif

let s:tagdir = expand('~/.cache/tags')
if !isdirectory(s:tagdir)
  call mkdir(s:tagdir, 'p')
endif
if filewritable(s:tagdir) == 2
  call s:report('PASS', 'gutentags 缓存目录可写', '')
else
  call s:report('WARN', 'gutentags 缓存目录不可写', 'mkdir -p ~/.cache/tags')
endif

try
  execute 'help myvim'
  helpclose
  call s:report('PASS', ':help myvim', '')
catch
  call s:report('WARN', ':help myvim 不可用', '运行 make help')
endtry

" 把累计报告输出到 stdout（-s 模式下 echom 不进 stdout，必须借 :! 打印）
let s:reportfile = tempname()
call writefile(s:lines, s:reportfile)
execute '!' . 'cat ' . shellescape(s:reportfile)
call delete(s:reportfile)

if s:fail
  cquit 1
endif
quit
```

- [ ] **Step 3: 运行完整 make verify**

Run: `make verify; echo "exit=$?"`
Expected: 每项一行 PASS/WARN；本机预期 WARN：`fzf 缺失`、`rg 缺失`、`instant-markdown-d 缺失`、`vim 无 python3`、`YCM 未编译`；无 FAIL；`exit=0`
（注：本机 `ctags` 是 BSD 系统自带 exuberant-ctags 兼容二进制，`verify.sh` 只验存在性 → PASS；真正的 ctags 兼容性由 .vimrc 守卫在运行时处理。）

- [ ] **Step 4: 验证 FAIL 会使退出码非 0（临时破坏法）**

> 注意：`make verify` 的依赖链含 `30-plugins.sh`，会自动 `PluginInstall` 把移走的 vim-fugitive 克隆回来，
> 导致直接 `make verify` 看不到 FAIL。要观察 FAIL，必须跳过安装步骤、直接调用 verify.vim。

Run:
```bash
mv ~/.vim/bundle/vim-fugitive /tmp/vim-fugitive-save
bash scripts/verify.sh >/dev/null 2>&1
vim -E -s -S scripts/verify.vim </dev/null; echo "verify.vim exit=$?"
mv /tmp/vim-fugitive-save ~/.vim/bundle/vim-fugitive
make verify >/dev/null 2>&1; echo "exit-after-restore=$?"
```
Expected: 输出含 `[FAIL] :Git → vim-fugitive 未装上？运行 make plugins`，`verify.vim exit=1`；恢复目录后 `make verify` 重新通过 `exit=0`

- [ ] **Step 5: Commit**

```bash
git add scripts/verify.sh scripts/verify.vim docs/superpowers/plans/2026-08-02-one-click-install.md
git commit -m "Add two-layer make verify: external deps + plugin capability smoke tests"
```

---

### Task 8: README 更新

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 重写「install myvim」小节，并新增依赖说明**

将 README 中 `## install myvim` 小节整体替换为：

````markdown
## install myvim

### 前置依赖

macOS（推荐用 brew 安装的 vim，自带 vim 无 python3，YCM/UltiSnips 不可用）：

```
brew install git vim fzf ripgrep ctags node
```

Linux：

```
sudo apt-get install -y git vim fzf ripgrep exuberant-ctags nodejs npm
```

### 一键安装

```
git clone https://github.com/XHao/myvim.git ~/.vim
cd ~/.vim
make install    # 或 sh init.sh（兼容入口）
```

安装末尾会自动运行 `make verify` 输出体检报告；WARN 项按提示处理即可。

### 常用 make 目标

| 目标 | 作用 |
|---|---|
| `make install` | 一键全装（子模块 → vimrc 软链 → 插件 → tern → help → verify） |
| `make update` | 更新子模块与全部插件 |
| `make verify` | 分层验证：外部依赖 + 插件能力冒烟测试 |
| `make plugins` / `tern` / `help` | 单独执行某一步 |

### 新增插件约定

往 .vimrc 加插件时，请同步：

1. `scripts/verify.vim` 加一行能力检查
2. `doc/myvim.txt` 加一节说明（`:help myvim`）
````

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "Update README: brew deps, make targets, new-plugin checklist"
```

---

### Task 9: 端到端验收

**Files:** 无（仅运行验证）

- [ ] **Step 1: make install 连跑两次，验证幂等**

Run: `make install && make install`
Expected: 第二次运行所有步骤显示"跳过/已就绪"；两次退出码均 0

- [ ] **Step 2: init.sh 兼容入口**

Run: `sh init.sh`
Expected: 等价于 make install，退出码 0

- [ ] **Step 3: vim 启动无报错**

Run: `vim -E -s -c "qa" </dev/null 2>&1; echo "exit=$?"`
Expected: `exit=0`，无错误输出

- [ ] **Step 4: git 工作区干净**

Run: `git status --short`
Expected: 无输出（doc/tags、bundle/* 均被忽略）

---

## Self-Review 记录

- Spec 覆盖：spec §1（安装体系）→ Task 1-4；§2（.vimrc 增强）→ Task 6；§3（verify）→ Task 7；§4（help 文档）→ Task 5；§5（README）→ Task 8；验证计划 → Task 9。无缺口。
- 占位符扫描：无 TBD/TODO；所有代码块为完整内容。
- 一致性：Makefile 的 verify 目标调用 `scripts/verify.sh` + `scripts/verify.vim`，与 Task 7 文件名一致；`make help` 的 helptags 路径与 doc/ 位置一致；verify.vim 检查的插件与 Task 6 新增插件一致。

---

### Task 10: python3 提前检测 + 条件插件 + make ycm

**背景：** 在 vim 缺少 `+python3` 的机器（如 macOS 自带 vim）上，原安装流程仍会克隆 YCM（178MB），并在每次 vim 启动时报 `YouCompleteMe unavailable`；WARN 只在 install 末尾出现。本任务：提前检测、按条件声明插件、提供 opt-in `make ycm` 编译目标。

**Files:**
- Create: `scripts/install.d/00-preflight.sh`
- Create: `scripts/install.d/50-ycm.sh`
- Modify: `Makefile`（preflight 作链头；新增 ycm 目标）
- Modify: `.vimrc`（YCM/UltiSnips 声明包入 `if has('python3')`）
- Modify: `scripts/verify.vim`（python3/YCM 检查嵌套）
- Modify: `doc/myvim.txt`、`README.md`

**Change 1: `scripts/install.d/00-preflight.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

require_cmd git "brew install git"
require_cmd vim "brew install vim"

# 提前检测 python3（YCM/UltiSnips 的硬性前提），不满足则提前提示
if vim -E -s -c "if !has('python3') | cquit | endif" -c "qa" </dev/null >/dev/null 2>&1; then
  ok "vim 支持 python3"
else
  warn "当前 vim 无 python3 支持，YCM/UltiSnips 将被跳过 → brew install vim"
fi
```

**Change 2: `Makefile`** — `.PHONY` 增 `preflight ycm`；新增 `preflight` 目标；`submodules: preflight`；尾部新增独立 `ycm` 目标（不进 install 链）：

```makefile
preflight:
	bash $(INSTALL_DIR)/00-preflight.sh

submodules: preflight
	bash $(INSTALL_DIR)/10-submodules.sh

...

ycm:
	bash $(INSTALL_DIR)/50-ycm.sh
```

**Change 3: `scripts/install.d/50-ycm.sh`**

```bash
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
```

**Change 4: `.vimrc`** — 原 4 行无条件 YCM/UltiSnips 声明包入条件：

```vim
" ycm + ultisnips（需 vim +python3，否则跳过声明，见 make verify 提示）
if has('python3')
  Plugin 'Valloric/YouCompleteMe'
  Plugin 'rdnetto/YCM-Generator'
  Plugin 'SirVer/ultisnips'
  Plugin 'honza/vim-snippets'
endif
```

后续 `g:ycm_*` / UltiSnips 设置块未改（插件缺失时无害）。

**Change 5: `scripts/verify.vim`** — python3/YCM 检查改为嵌套（无 python3 时只一行 WARN，不再单独报 YCM 未编译）：

```vim
if has('python3')
  call s:report('PASS', 'vim +python3', '')
  if empty(glob(expand('~/.vim/bundle/YouCompleteMe/third_party/ycmd/ycm_core*')))
    call s:report('WARN', 'YCM 未编译', 'make ycm')
  else
    call s:report('PASS', 'YCM 已编译', '')
  endif
else
  call s:report('WARN', 'vim 无 python3，YCM/UltiSnips 已按条件跳过', 'brew install vim')
endif
```

**Change 6/7:** `doc/myvim.txt` YouCompleteMe 行改为 `（需 vim +python3，否则不声明；编译用 make ycm）`，UltiSnips 行改为 `（需 python3，否则不声明）`；`README.md` 常用 make 目标表新增 `| make ycm | 编译 YouCompleteMe（需 vim +python3，幂等） |`。

