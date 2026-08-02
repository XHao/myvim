# 一键安装与 vim 配置增强设计

日期：2026-08-02
状态：待评审

## 背景

`~/.vim` 是个人 vim 配置仓库（Vundle 插件体系）。现有 `init.sh` 在本机（macOS）实测暴露以下问题：

1. `[ -f "~/.vimrc" ]` 引号内 `~` 不展开，备份逻辑永假；`ln -s` 无 `-f`，已有 vimrc 时报错退出
2. macOS 无 `wget`，c-support 下载必失败；且无 `set -e`，失败后脚本"静默成功"
3. `vi +PluginInstall! +qall` 是交互式的，会卡在 vim 界面，无法真正一键
4. `cp molokai/colors/molokai.vim` 冗余（仓库已提交相同文件）
5. c-support 插件下载后从未被 .vimrc 配置，属死代码
6. macOS 自带 vim 无 `+python3`，YCM/UltiSnips 不可用；tern 的 `npm install` 钩子未执行；这些问题装完无任何提示

## 目标

1. Makefile 驱动的模块化一键安装：幂等、错误分级、跨 macOS/Linux
2. 插件栈增强：引入 4 个高价值插件，移除死代码
3. 安装后分层验证（`make verify`）：外部依赖 + 插件能力冒烟测试，暴露不兼容
4. vim 内置帮助文档：`:help myvim` 查阅所有插件能力

## 非目标

- 不自动安装 vim 本体、不自动编译 YouCompleteMe、不自动装全局 npm 包（仅检测并提示命令）
- 不引入 coc.nvim/ALE（与 YCM 职责重叠）

## 设计

### 1. 安装体系

```
Makefile                  # 统一入口
init.sh                   # 兼容入口，转调 make install
scripts/
  common.sh               # 日志(info/ok/warn/err)、OS 检测、require_cmd
  install.d/
    10-submodules.sh      # git submodule update --init
    20-vimrc.sh           # 备份已有 ~/.vimrc → 建软链（幂等）
    30-plugins.sh         # 无头 vim -E -s 跑 PluginInstall + helptags
    40-tern.sh            # tern_for_vim 下 npm install（无 npm 则警告跳过）
  verify.vim              # 插件能力冒烟测试（vim -es -S 执行）
doc/
  myvim.txt               # 插件能力帮助文档（:help myvim）
```

Makefile 目标：

| 目标 | 作用 |
|---|---|
| `make install` | 一键全装 = submodules + vimrc + plugins + tern + help + verify |
| `make submodules` / `vimrc` / `plugins` / `tern` | 单独执行某一步 |
| `make help` | 生成 doc/tags |
| `make update` | 更新子模块 + `PluginInstall!` 更新插件 |
| `make verify` | 分层验证（见第 3 节） |

行为约定：

- 所有脚本 `set -euo pipefail`，`source scripts/common.sh`
- **幂等**：每步先检查再行动（vimrc 已是指向本仓库的软链则跳过；tern 已有 node_modules 则跳过），重复运行全部显示"跳过/已就绪"且退出码 0
- **错误分级**：submodules / vimrc 软链失败 → 中断；tern/npm/python3/YCM 未编译 → WARN 继续
- **备份修复**：已有 `~/.vimrc`（文件或非本仓库软链）备份为 `~/.vimrc.bak.YYYYMMDD`
- 移除 c-support 下载步骤与冗余 molokai cp 步骤
- PluginInstall 使用无头模式：`vim -E -s -c "source $HOME/.vimrc" -c "PluginInstall" -c "qa" </dev/null`

### 2. .vimrc 增强

新增插件：

- `junegunn/fzf` + `junegunn/fzf.vim` — 模糊查找文件/内容（`<C-p>` 找文件、`<leader>rg` 全文搜索）
- `tpope/vim-fugitive` — vim 内 Git 操作
- `jiangmiao/auto-pairs` — 括号/引号自动配对
- `ludovicchabant/vim-gutentags` — 自动维护 ctags（tags 缓存到 `~/.cache/tags`，项目根标记 `.git`）

移除：

- 自研 `ClosePair`/`QuoteDelim` 函数及 8 条括号/引号 inoremap（auto-pairs 接管）
- 被 fzf 替代的老旧三件套：`vim-scripts/indexer.tar.gz`、`vim-scripts/DfrankUtil`、`vim-scripts/vimprj`

新增配置：

- fzf：`<C-p>` → `:Files`，`<leader>rg` → `:Rg`
- gutentags：cache dir、项目根标记

### 3. `make verify` 分层验证

第 1 层（shell，scripts 内）：`fzf`、`rg`、`ctags`、`node`/`npm`、`instant-markdown-d` 是否存在；缺失给 WARN + 安装提示（如 `brew install ripgrep`）。

第 2 层（`scripts/verify.vim`，无头执行）：

- 命令存在性（`exists(":Cmd") == 2`）：NERDTreeToggle、TagbarToggle、Files、Rg、Git、AutoFormatBuffer 等
- colorscheme molokai 可加载
- `has('python3')`（YCM/UltiSnips 硬性前提，缺失记 WARN 并提示 `brew install vim`）
- YCM 专项：`ycm_core` 编译产物是否存在，未编译提示 `./install.py` 命令
- gutentags 专项：tags 缓存目录可写
- `:help myvim` 标签可跳转

输出与退出码：

- 每项一行 `PASS / WARN / FAIL` + 修复提示
- FAIL（插件未装上等关键缺失）→ 退出码非 0；WARN（可选能力缺失）→ 不阻塞
- 约定：新增插件入 .vimrc 时，须在 verify.vim 登记一行、在 doc/myvim.txt 加一节（写入 README）

### 4. 帮助文档

- `doc/myvim.txt`：vim help 格式，`*myvim*` 标签；按插件分节列出用途、命令、快捷键（与 .vimrc 实际配置一致）
- `.gitignore`：移除 `doc/` 忽略项，改为只忽略 `doc/tags`（生成物）
- `make install` 末尾执行 `helptags` 生成 tags
- 文档随插件变更手工维护

### 5. README 更新

- macOS 前置说明（brew 安装 vim/fzf/ripgrep/ctags）
- `make` 用法表
- "新增插件三件套"约定：.vimrc + verify.vim + doc/myvim.txt

## 验证计划

1. `make install` 在当前机器连跑两次：第二次全部幂等跳过，退出码 0
2. `make verify` 输出 PASS/WARN 清单，当前机器预期 WARN：python3 缺失、ycmd 未编译
3. `vim -es` 启动无报错
4. vim 内 `:help myvim` 可打开
