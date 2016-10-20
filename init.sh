#!/usr/bin/env bash

git submodule init

git submodule update

echo "copy color theme..."
cp ~/.vim/molokai/colors/molokai.vim ~/.vim/colors/molokai.vim

echo "backup origin vimrc..."
if [ -f "$HOME/.vimrc" ]; then
    mv ~/.vimrc ~/.vimrc.`date +%Y%m%d`
fi

echo "create new vimrc..."
ln -s ~/.vim/.vimrc ~/.vimrc

VIM_HOME=$HOME/.vim

vi +PluginInstall! +qall

if [ ! -f "$VIM_HOME/c-support.zip" ]; then
    echo "download c-support plugin"
    curl -o c-support.zip http://www.vim.org/scripts/download_script.php?src_id=24474
    unzip -o c-support.zip
else
    echo "has c-support.zip in dir"
fi


#end of file
