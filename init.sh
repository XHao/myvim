#!/usr/bin/env bash
# 兼容入口：等价于 make install
set -euo pipefail
cd "$(dirname "$0")"
exec make install
