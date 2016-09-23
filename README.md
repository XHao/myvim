# myvim

this is the vim configuration

## Install

### install git

### clone myvim repository

* `git clone https://github.com/XHao/myvim.git ~/.vim`
* `cd ~/.vim`
* `sh init.sh`

after these steps, myvim is add to your computer

## plugins

### [YouCompleteMe](https://github.com/Valloric/YouCompleteMe)

YCM本身需要编译之后才能使用，所以每次更新之后都要重新编译

```
cd ~/.vim/bundle/YouCompleteMe
./install.py --all
```

*tips*:如果想要直接启用参数`--all`，必须确保`xbuild, go, tsserver, node, npm, rustc, and cargo tools are installed and in your PATH`,否则只能根据你需要的语言插件进行编译
