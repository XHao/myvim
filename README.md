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

* `git clone https://github.com/XHao/myvim.git ~/.vim`
* `cd ~/.vim`
* `sh init.sh`

*after these steps, myvim is add to your computer*

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
