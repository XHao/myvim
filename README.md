# myvim

this is the vim configuration

## pre-condition

### install git

### install vim

* git clone https://github.com/vim/vim.git
* 安装python-dev：sudo apt-get install -y python-dev
* cd vim
* ./configure --with-features=huge --enable-multibyte --enable-rubyinterp=yes --enable-pythoninterp=yes --with-python-config-dir=/usr/lib/python2.7/config-x86_64-linux-gnu --enable-perlinterp=yes --enable-luainterp=yes
* sudo make install

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

## plugins

### [YouCompleteMe](https://github.com/Valloric/YouCompleteMe)

YCM本身需要编译之后才能使用，所以每次更新之后都要重新编译

```
cd ~/.vim/bundle/YouCompleteMe
./install.py --all
```

*tips*:如果想要直接启用参数`--all`，必须确保`xbuild, go, tsserver, node, npm, rustc, and cargo tools are installed and in your PATH`,否则只能根据你需要的语言插件进行编译

### [vim-instant-markdown](https://github.com/suan/vim-instant-markdown)

需要安装instant-markdown-d：`npm -g install instant-markdown-d`

Copy the after/ftplugin/markdown/instant-markdown.vim file from this repo into your ~/.vim/after/ftplugin/markdown/ (creating directories as necessary), or follow your vim package manager's instructions.
