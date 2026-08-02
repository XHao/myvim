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

注意：YCM/UltiSnips 需要 python3 支持，编译后可用 `vim --version | grep python3` 确认是 `+python3`。

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

注意：Ubuntu 默认的 vim 可能不含 python3 支持（可改装 vim-nox），否则 YCM/UltiSnips 不可用；`make verify` 会检测并提示。

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
| `make update` | 更新子模块与全部插件（更新后建议 `make verify` 复检） |
| `make verify` | 分层验证：外部依赖 + 插件能力冒烟测试 |
| `make plugins` / `tern` / `help` | 单独执行某一步 |

### 新增插件约定

往 .vimrc 加插件时，请同步：

1. `scripts/verify.vim` 加一行能力检查
2. `doc/myvim.txt` 加一节说明（`:help myvim`）

## plugins

### [YouCompleteMe](https://github.com/Valloric/YouCompleteMe)

YCM本身需要编译之后才能使用，所以每次更新之后都要重新编译

```
cd ~/.vim/bundle/YouCompleteMe
./install.py --clangd-completer
```

*tips*：`--clangd-completer` 是轻量可靠的默认选择；如需更多语言支持可改用 `--all`，但必须确保 `xbuild, go, tsserver, node, npm, rustc, and cargo tools are installed and in your PATH`。

### [vim-instant-markdown](https://github.com/suan/vim-instant-markdown)

需要安装instant-markdown-d：`npm -g install instant-markdown-d`

插件由 Vundle 安装，自带的 ftplugin 会自动生效，无需额外拷贝文件。
