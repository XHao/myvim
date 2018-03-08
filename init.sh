#!/usr/bin/env bash

git submodule init

git submodule update

echo "copy color theme..."
cp ~/.vim/molokai/colors/molokai.vim ~/.vim/colors/molokai.vim

echo "backup origin vimrc..."
if [ -f "~/.vimrc" ]; then
    mv ~/.vimrc ~/.vimrc.`date +%Y%m%d`
fi

echo "create new vimrc..."
ln -s ~/.vim/.vimrc ~/.vimrc

vi +PluginInstall! +qall

if [ ! -f "~/c-support.zip" ]; then
    echo "download c-support plugin"
    wget -O c-support.zip http://www.vim.org/scripts/download_script.php?src_id=24474
    unzip -o c-support.zip
else
    echo "has c-support.zip in dir"
fi

#end of file
