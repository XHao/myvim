#!/usr/bin/env bash
# 公共函数库：日志、依赖检查。只能被 source，不要直接执行。

if [[ -t 1 ]]; then
  C_INFO='\033[0;34m'; C_OK='\033[0;32m'; C_WARN='\033[0;33m'; C_ERR='\033[0;31m'; C_OFF='\033[0m'
else
  C_INFO=''; C_OK=''; C_WARN=''; C_ERR=''; C_OFF=''
fi

info() { printf "${C_INFO}[INFO]${C_OFF} %s\n" "$*"; }
ok()   { printf "${C_OK}[ OK ]${C_OFF} %s\n" "$*"; }
warn() { printf "${C_WARN}[WARN]${C_OFF} %s\n" "$*"; }
err()  { printf "${C_ERR}[FAIL]${C_OFF} %s\n" "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

require_cmd() {
  if ! have "$1"; then
    err "缺少必需命令: $1 → $2"
    exit 1
  fi
}
