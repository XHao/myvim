#!/usr/bin/env bash
set -uo pipefail
source "$(dirname "$0")/common.sh"

FAILED=0

check_bin() {
  # $1 命令名  $2 安装提示  $3 级别(WARN/FAIL)
  if have "$1"; then
    ok "$1"
  elif [ "$3" = "FAIL" ]; then
    err "$1 缺失 → $2"
    FAILED=1
  else
    warn "$1 缺失 → $2"
  fi
}

check_bin git    "brew install git"                     FAIL
check_bin vim    "brew install vim"                     FAIL
check_bin fzf    "make deps"                            WARN
check_bin rg     "make deps"                            WARN
check_bin ctags  "brew install ctags"                   WARN
check_bin node   "brew install node"                    WARN
check_bin npm    "brew install node"                    WARN
check_bin instant-markdown-d "make deps"                WARN

exit $FAILED
