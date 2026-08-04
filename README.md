# myvim

this is the vim configuration

## pre-condition

通常只需按下方「前置依赖」用包管理器安装 vim 即可；本节仅在需要自行编译 vim 时参考。

### install git

### install vim（从源码编译，可选）

* git clone https://github.com/vim/vim.git
* 安装python3-dev：sudo apt-get install -y python3-dev
* cd vim
* ./configure --with-features=huge --enable-multibyte --enable-rubyinterp=yes --enable-python3interp=yes --enable-perlinterp=yes --enable-luainterp=yes
* sudo make install

注意：UltiSnips 需要 python3 支持，编译后可用 `vim --version | grep python3` 确认是 `+python3`。

## install myvim

### 前置依赖

macOS（推荐用 brew 安装的 vim，自带 vim 无 python3，UltiSnips 不可用）：

```
brew install git vim ctags node
```

Linux：

```
sudo apt-get install -y git vim exuberant-ctags nodejs npm
```

fzf、ripgrep、instant-markdown-d 由 `make install` 自动安装（检测 brew/apt-get，失败仅 WARN 不中断）；也可单独 `make deps` 触发。

注意：Ubuntu 默认的 vim 可能不含 python3 支持（可改装 vim-nox），否则 UltiSnips 不可用；`make verify` 会检测并提示。

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
| `make install` | 一键全装（前置检测 → 可选依赖 → 子模块 → vimrc 软链 → 插件 → help → verify） |
| `make deps` | 自动安装可选依赖 fzf / ripgrep / instant-markdown-d（brew/apt-get，幂等） |
| `make update` | 更新子模块与全部插件（更新后建议 `make verify` 复检） |
| `make verify` | 分层验证：外部依赖 + 插件能力冒烟测试 |
| `make coding` | 安装 LSP servers + 格式化器（pyright/gopls/jdtls/clang-format/black/google-java-format/prettier；不进入 make install 主流程） |
| `make plugins` / `help` | 单独执行某一步 |

### 新增插件约定

往 .vimrc 加插件时，请同步：

1. `scripts/verify.vim` 加一行能力检查
2. `doc/myvim.txt` 加一节说明（`:help myvim`）

### 已安装插件一览

`make install` 后，以下插件克隆到 `~/.vim/plugged/`。带 ⚡ 的按文件类型延迟加载（打开对应文件才加载，加快启动）。各插件的命令与快捷键详见 `:help myvim`。

| 类别 | 插件 |
|---|---|
| 补全 / 片段 | ultisnips *, vim-snippets * |
| LSP / Go 开发 | vim-lsp, asyncomplete.vim, vim-go |
| 文件 / 跳转 | nerdtree, nerdtree-git-plugin, tagbar, fzf, fzf.vim, vim-fswitch ⚡, vim-gutentags |
| Git | vim-fugitive |
| 编辑增强 | auto-pairs, nerdcommenter, tabular ⚡ |
| 语言支持 | vim-cpp-enhanced-highlight ⚡, pangloss/vim-javascript ⚡, moll/vim-node ⚡, vim-markdown ⚡, vim-instant-markdown ⚡ |
| 界面 / 格式化 | vim-airline, vim-indent-guides, vim-codefmt, vim-maktaba, vim-glaive, molokai（配色，独立文件 + submodule） |

带 * 的需 `vim +python3`（macOS 自带 vim 无，须 `brew install vim`）。`.vimrc` 中 `if has('python3')` 守卫会自动跳过未满足的声明，不影响其他插件。带 ⚡ 的按文件类型延迟加载。

## plugins

### LSP servers (vim-lsp + pyright/gopls/jdtls/clangd)

**重要**：`make install` 只克隆 vim 插件到 `~/.vim/plugged/`，**不装** LSP servers 与格式化器。要使用语义补全、跳转、code action 等现代 IDE 能力，必须单独执行：

```
make coding    # 装 pyright/gopls/jdtls LSP servers + clang-format/black/google-java-format/prettier 格式化器
```

各组件来源：
- `clangd`（C++）：系统自带（Xcode CLT），无需 `make coding`
- `pyright`（Python）：npm registry，`npm install -g pyright`
- `gopls`（Go）：proxy.golang.org，`go install golang.org/x/tools/gopls@latest`
- `jdtls`（Java）：brew bottle / ghcr.io，`brew install jdtls`

`make coding` 幂等，已装的组件会跳过。完成后 `make verify` 中相关 `[WARN]` 全部转为 `[PASS]`。

### [vim-instant-markdown](https://github.com/suan/vim-instant-markdown)

需要安装instant-markdown-d：`npm -g install instant-markdown-d`

插件由 vim-plug 安装，自带的 ftplugin 会自动生效，无需额外拷贝文件。

### 从 Vundle 迁移

2026-08 起插件管理器由 Vundle 换为 vim-plug，插件目录从 `bundle/` 变为 `plugged/`。
升级后旧目录可手动删除：`rm -rf ~/.vim/bundle`
