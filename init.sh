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

vi +PluginInstall! +qall

echo "download c-support plugin"
if [ ! -f "c-support.zip" ]; then
    curl -o c-support.zip http://www.vim.org/scripts/download_script.php?src_id=24474
    unzip -o c-support.zip
fi


#end of file
