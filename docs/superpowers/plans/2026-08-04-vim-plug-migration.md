# vim-plug 迁移 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将插件管理器从 Vundle 迁移到 vim-plug，清理 4 个过时插件，启用保守的延迟加载。

**Architecture:** vendor `autoload/plug.vim` 入仓库替代 Vundle 子模块；插件改装到 `~/.vim/plugged`；安装链路（Makefile + install.d + verify）保持结构不变，仅替换命令与路径。

**Tech Stack:** bash、Makefile、vim-plug、vim script。

**Spec:** `docs/superpowers/specs/2026-08-04-vim-plug-migration-design.md`

**全局约定：**
- 所有 bash 脚本以 `#!/usr/bin/env bash` + `set -euo pipefail` 开头
- 脚本幂等（重复运行显示"跳过"）
- Makefile 配方行缩进必须是 Tab
- 本会话 Bash 环境 PATH 中 /usr/bin 在 /opt/homebrew/bin 前，验证命令如需 brew vim（+python3）须前缀 `PATH=/opt/homebrew/bin:$PATH`
- 每次修复同步更新本计划文档，保持计划与实现一致

---

### Task 1: vendor plug.vim + 移除 Vundle 子模块 + .gitignore 调整

**Files:**
- Create: `autoload/plug.vim`（curl 下载）
- Modify: `.gitmodules`（删 Vundle.vim 条目）
- Modify: `.gitignore`（删 `autoload/`，加 `plugged/`）
- Remove: `bundle/Vundle.vim` gitlink

- [x] **Step 1: 下载 plug.vim**

Run:
```bash
mkdir -p /Users/shako/.vim/autoload
curl -fLo /Users/shako/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```
Expected: 无错误输出；`head -3 autoload/plug.vim` 显示 vim-plug 文件头注释

- [x] **Step 2: 移除 Vundle 子模块**

Run:
```bash
cd /Users/shako/.vim
git submodule deinit -f bundle/Vundle.vim
git rm -f bundle/Vundle.vim
```
Expected: `.gitmodules` 只剩 molokai 条目；`git ls-files | grep -c bundle` 输出 0

- [x] **Step 3: 调整 .gitignore**

删除 `autoload/` 行（否则 plug.vim 无法被 git 跟踪），在 `bundle/*` 行后新增 `plugged/`。改后相关部分：

```
bundle/*
plugged/
.DS_Store
```

- [x] **Step 4: 验证**

Run:
```bash
cd /Users/shako/.vim
git check-ignore -v autoload/plug.vim; echo "exit=$?"
grep -n 'plugged' .gitignore
```
Expected: check-ignore 无匹配输出且 `exit=1`（即不被忽略）；.gitignore 含 `plugged/` 行

- [x] **Step 5: Commit**

```bash
git add autoload/plug.vim .gitmodules .gitignore
git commit -m "Vendor vim-plug; remove Vundle submodule"
```

---

### Task 2: .vimrc 改造（plug 声明 + 清单变更 + 延迟加载 + 删死配置）

**Files:**
- Modify: `.vimrc`

- [ ] **Step 1: 替换插件管理块**

将 .vimrc 中（约 22-81 行）从 `set nocompatible` 到 `filetype plugin indent on    " required"` 的整段 Vundle 块替换为：

```vim
set nocompatible              " be iMproved, required

" vim-plug 插件管理（plug.vim 已 vendor 在 ~/.vim/autoload/）
call plug#begin('~/.vim/plugged')

" ycm + ultisnips（需 vim +python3，否则跳过声明，见 make verify 提示）
if has('python3')
  Plug 'Valloric/YouCompleteMe'
  Plug 'rdnetto/YCM-Generator'
  Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'
endif

Plug 'vim-airline/vim-airline'
Plug 'moll/vim-node', { 'for': 'javascript' }
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'godlygeek/tabular', { 'for': 'markdown' }
Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }
Plug 'suan/vim-instant-markdown', { 'for': 'markdown' }
Plug 'majutsushi/tagbar'
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'octol/vim-cpp-enhanced-highlight', { 'for': ['c', 'cpp'] }
Plug 'nathanaelkane/vim-indent-guides'
Plug 'derekwyatt/vim-fswitch', { 'for': ['c', 'cpp'] }
Plug 'google/vim-maktaba'
Plug 'google/vim-codefmt'
Plug 'google/vim-glaive'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-fugitive'
Plug 'jiangmiao/auto-pairs'
Plug 'ludovicchabant/vim-gutentags'
Plug 'scrooloose/nerdcommenter'

call plug#end()
filetype plugin indent on
```

注意：
- 删除原 `filetype off`、`set rtp+=~/.vim/bundle/Vundle.vim`
- 删除被移除插件的声明：tern_for_vim、vim-javacomplete2、jelera/vim-javascript-syntax、单名 `node`
- 保留原注释结构（fzf/gutentags 等中文注释按需保留在对应 Plug 行上方）

- [ ] **Step 2: 删除 tern 配置与 JavaScriptFold**

删除以下行：
```vim
let tern_show_signature_in_pum = 1
let tern_show_argument_hints = 'on_hold'
autocmd FileType javascript nnoremap <leader>d :TernDef<CR>
```
```vim
au FileType javascript call JavaScriptFold()
```

- [ ] **Step 3: YCM extra_conf 路径改 plugged**

```vim
let g:ycm_global_ycm_extra_conf = '~/.vim/plugged/YouCompleteMe/third_party/ycmd/.ycm_extra_conf.py'
```

- [ ] **Step 4: 去重 filetype**

确认全文只有一处 `filetype plugin indent on`（原文件有两处，删第二处）。

- [ ] **Step 5: 验证无头加载无报错**

Run:
```bash
vim -E -s -c 'source $HOME/.vimrc' -c 'verbose echo exists(":PlugInstall")' -c 'qa' </dev/null 2>&1 | tail -3
```
Expected: 输出 `2`（命令存在）；无 E 开头错误（此时 plugged/ 为空属正常，plug 不报错）

- [ ] **Step 6: Commit**

```bash
git add .vimrc
git commit -m "Migrate plugin declarations to vim-plug; drop tern/javacomplete2; lazy-load ft plugins"
```

---

### Task 3: 安装脚本与 Makefile 适配

**Files:**
- Modify: `scripts/install.d/30-plugins.sh`
- Modify: `Makefile`
- Remove: `scripts/install.d/40-tern.sh`
- Modify: `scripts/install.d/50-ycm.sh`
- Modify: `scripts/verify.vim`

- [ ] **Step 1: 30-plugins.sh 换 PlugInstall --sync**

全文替换为：

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

require_cmd vim "brew install vim"

info "无头模式安装 vim-plug 插件..."
# 注意：单个插件克隆失败不会反映到本脚本退出码，由 make verify 兜底检测
vim -E -s -c 'source $HOME/.vimrc' -c "PlugInstall --sync" -c "qa" </dev/null
ok "插件安装完成"
```

- [ ] **Step 2: Makefile 删 tern、改 update**

- `.PHONY` 删除 `tern`
- 删除 `tern: plugins` 目标整段
- `help: tern` 改为 `help: plugins`
- `update` 目标改为：

```makefile
update:
	git submodule update --init
	vim -E -s -c 'source $$HOME/.vimrc' -c "PlugUpdate --sync" -c "qa" </dev/null
```

- [ ] **Step 3: 删除 40-tern.sh**

Run: `git rm scripts/install.d/40-tern.sh`

- [ ] **Step 4: 50-ycm.sh 路径改 plugged**

```bash
YCM_DIR="$HOME/.vim/plugged/YouCompleteMe"
```

- [ ] **Step 5: verify.vim 两处改动**

ycm_core 探测改 plugged 路径：
```vim
if empty(glob(expand('~/.vim/plugged/YouCompleteMe/third_party/ycmd/ycm_core*')))
```

在命令存在性检查区新增一行（插件管理器自检）：
```vim
call s:check_cmd('PlugInstall')
```

- [ ] **Step 6: 验证**

Run:
```bash
bash -n scripts/install.d/30-plugins.sh && bash -n scripts/install.d/50-ycm.sh && echo "syntax OK"
make -C /Users/shako/.vim -n update | tail -2
grep -c 'tern' Makefile; echo "（应为 0）"
```
Expected: syntax OK；update 干跑显示 PlugUpdate --sync；Makefile 无 tern

- [ ] **Step 7: Commit**

```bash
git add scripts/install.d/30-plugins.sh scripts/install.d/50-ycm.sh scripts/verify.vim Makefile
git commit -m "Adapt install scripts to vim-plug; drop tern step"
```

---

### Task 4: 文档同步（README + doc/myvim.txt）

**Files:**
- Modify: `README.md`
- Modify: `doc/myvim.txt`

- [ ] **Step 1: README 改动**

- 「插件由 Vundle 安装」→「插件由 vim-plug 安装」
- make 目标表删除 `make plugins` 行中的 tern 提及；`make install` 描述中「→ tern →」删除
- YCM 编译路径 `cd ~/.vim/bundle/YouCompleteMe` → `cd ~/.vim/plugged/YouCompleteMe`
- 在「一键安装」小节末尾追加一段：

```markdown
### 从 Vundle 迁移

2026-08 起插件管理器由 Vundle 换为 vim-plug，插件目录从 `bundle/` 变为 `plugged/`。
升级后旧目录可手动删除：`rm -rf ~/.vim/bundle`
```

- [ ] **Step 2: doc/myvim.txt 改动**

- 删除 tern_for_vim、vim-javacomplete2、vim-javascript-syntax 相关小节
- 新增 pangloss/vim-javascript 一行说明
- 插件管理命令说明改为 `:PlugInstall` / `:PlugUpdate` / `:PlugStatus`
- 文件内所有 bundle 路径引用改 plugged

- [ ] **Step 3: 验证**

Run:
```bash
grep -in 'vundle\|tern\|javacomplete\|bundle/' README.md doc/myvim.txt | grep -v '从 Vundle 迁移\|由 Vundle 换为'
```
Expected: 无输出（除迁移说明段外无残留）

- [ ] **Step 4: Commit**

```bash
git add README.md doc/myvim.txt
git commit -m "Update docs for vim-plug migration"
```

---

### Task 5: 端到端验证（全量重装 + 幂等 + 延迟加载 + YCM 恢复）

**Files:** 无（纯验证）

- [ ] **Step 1: 全新安装（brew vim，含 python3）**

Run:
```bash
PATH=/opt/homebrew/bin:$PATH make -C /Users/shako/.vim install 2>&1 | tail -30
```
Expected: 插件并行克隆到 plugged/；preflight 显示 `[ OK ] vim 支持 python3`；verify 段 python3/YCM 检查为 PASS 或「YCM 未编译 → make ycm」WARN；退出码 0

- [ ] **Step 2: 幂等复跑**

Run:
```bash
PATH=/opt/homebrew/bin:$PATH make -C /Users/shako/.vim install 2>&1 | grep -c '跳过\|Already'
echo "exit=$?"
```
Expected: 多个"跳过"；退出码 0

- [ ] **Step 3: 延迟加载验证**

Run:
```bash
cd /tmp && echo 'var x = 1;' > t.js && echo '# hi' > t.md
PATH=/opt/homebrew/bin:$PATH vim -E -s -c 'edit /tmp/t.js' -c 'redir! > /tmp/js-scripts | silent scriptnames | redir END | qa' </dev/null
grep -c 'vim-javascript' /tmp/js-scripts
PATH=/opt/homebrew/bin:$PATH vim -E -s -c 'redir! > /tmp/nojs-scripts | silent scriptnames | redir END | qa' </dev/null
grep -c 'vim-javascript' /tmp/nojs-scripts; echo "（应为 0）"
```
Expected: 打开 .js 后 vim-javascript 已加载（≥1）；未打开时为 0

- [ ] **Step 4: 启动与帮助**

Run:
```bash
PATH=/opt/homebrew/bin:$PATH vim -E -s -c 'qa' </dev/null 2>&1 | head -5
PATH=/opt/homebrew/bin:$PATH vim -E -s -c 'help myvim' -c 'echo expand("%:t")' -c 'qa' </dev/null 2>&1 | tail -1
```
Expected: 启动无错误输出；help 打开 myvim.txt

- [ ] **Step 5: 更新本计划文档勾选状态，提交**

```bash
git add docs/superpowers/plans/2026-08-04-vim-plug-migration.md
git commit -m "Verify vim-plug migration end-to-end"
```
