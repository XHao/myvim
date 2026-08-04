#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../common.sh"

VIMRC_SRC="$HOME/.vim/.vimrc"
VIMRC_DST="$HOME/.vimrc"

# 已是指向本仓库的软链（含相对软链）→ 幂等跳过
if [ -L "$VIMRC_DST" ]; then
  CURTARGET="$(readlink "$VIMRC_DST")"
  case "$CURTARGET" in
    /*) ;;
    *)  CURTARGET="$(dirname "$VIMRC_DST")/$CURTARGET" ;;
  esac
  CURTARGET="${CURTARGET%/}"
  if [ "$CURTARGET" = "$VIMRC_SRC" ]; then
    ok "~/.vimrc 已链接到本仓库，跳过"
    exit 0
  fi
fi

# 存在其它文件或软链 → 备份后替换
if [ -e "$VIMRC_DST" ] || [ -L "$VIMRC_DST" ]; then
  BACKUP="$VIMRC_DST.bak.$(date +%Y%m%d)"
  n=1
  while [ -e "$BACKUP" ] || [ -L "$BACKUP" ]; do
    BACKUP="$VIMRC_DST.bak.$(date +%Y%m%d).$n"
    n=$((n+1))
  done
  warn "备份已有 ~/.vimrc → $BACKUP"
  mv "$VIMRC_DST" "$BACKUP"
fi

ln -s "$VIMRC_SRC" "$VIMRC_DST"
ok "已创建软链 ~/.vimrc → $VIMRC_SRC"
