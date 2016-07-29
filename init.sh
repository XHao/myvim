#!/usr/bin/env bash

echo "copy color theme..."
cp ~/.vim/molokai/colors/molokai.vim ~/.vim/colors/molokai.vim

echo "backup origin vimrc..."
if [ -f "$HOME/.vimrc" ]; then
    mv ~/.vimrc ~/.vimrc.`date +%Y%m%d`
fi

echo "create new vimrc..."
ln -s ~/.vim/.vimrc ~/.vimrc


if [ -f "$HOME/.vimrc_keymap" ]; then
    mv ~/.vimrc_keymap ~/.vimrc_keymap.`date +%Y%m%d`
fi
ln -s ~/.vim/.vimrc_keymap ~/.vimrc_keymap

vi +PluginInstall! +qall

#end of file
