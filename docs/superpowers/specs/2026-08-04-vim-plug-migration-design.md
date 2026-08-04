# vim-plug 迁移设计

日期：2026-08-04
状态：已确认（用户批准六节设计 + 四项清理全选）

## 背景

当前 `~/.vim` 使用 Vundle 管理插件（`bundle/Vundle.vim` 子模块 + `Plugin` 声明）。Vundle 已多年停止维护；社区主流 vim-plug 提供并行克隆、延迟加载、`do` 钩子等能力。现有安装体系（Makefile + scripts/install.d + make verify）已成熟，迁移必须保持这些能力不变。

同时借机清理过时插件：

| 插件 | 最后提交 | 处置 |
|---|---|---|
| tern_for_vim | 2019 | 移除（YCM TSServer 接管 JS/TS 补全） |
| vim-javacomplete2 | 2022 | 移除（.vimrc 已标注 slow/cpu；Java 保留 ctags/tagbar） |
| jelera/vim-javascript-syntax | 2020 | 换 pangloss/vim-javascript |
| vim-scripts/node（镜像） | — | 换正源 moll/vim-node |

## 目标

1. Vundle → vim-plug 等价替换：声明语法、安装/更新命令、脚本适配
2. 清理上表 4 项；新增 pangloss/vim-javascript
3. 纯 filetype 插件延迟加载（保守子集）
4. 文档同步（README、doc/myvim.txt）

## 非目标

- 不迁移到 LSP/coc.nvim（YCM 保留）
- 不改变 YCM opt-in 编译策略（`make ycm`，不加 `do` 钩子）
- 不自动删除旧 `bundle/` 目录（README 注明手动清理）

## 设计

### 1. 插件管理器接入

- 移除 `bundle/Vundle.vim` 子模块（`git submodule deinit` + 删 gitlink + 清 .gitmodules 条目），molokai 子模块保留
- **vendor** `plug.vim` 到仓库 `autoload/plug.vim`（提交入 git，安装零网络依赖；日后 `vim +PlugUpgrade` 自升级）
- .vimrc 头部：`set rtp+=~/.vim/bundle/Vundle.vim` + `vundle#begin/end` → `call plug#begin('~/.vim/plugged')` / `call plug#end()`
- 删除冗余 `filetype off` 与重复的 `filetype plugin indent on`（plug#end 自动处理）
- `Plugin 'vim-airline'` 写全为 `Plug 'vim-airline/vim-airline'`（消除单名歧义）

### 2. 插件目录 bundle → plugged

- 全部插件重新克隆到 `~/.vim/plugged`（并行，显著快于 Vundle）
- 同步路径引用三处：
  - `scripts/install.d/50-ycm.sh` 的 `YCM_DIR`
  - `scripts/verify.vim` 的 ycm_core 探测 glob
  - `.vimrc` 的 `g:ycm_global_ycm_extra_conf`

### 3. 插件清单变更

移除：`tern_for_vim`、`vim-javacomplete2`、`jelera/vim-javascript-syntax`

新增/替换：`pangloss/vim-javascript`、`moll/vim-node`

连带删除配置：
- .vimrc tern 三行（`tern_show_signature_in_pum`、`tern_show_argument_hints`、`TernDef` autocmd）
- `au FileType javascript call JavaScriptFold()`（JavaScriptFold 由被移除的 jelera 插件提供，pangloss 用 syntax 折叠）
- `scripts/install.d/40-tern.sh` 整文件 + Makefile tern 目标

`if has('python3')` 条件声明块（YCM/UltiSnips）保持不变。

### 4. 延迟加载（保守子集）

- `for: 'javascript'`：pangloss/vim-javascript、moll/vim-node
- `for: ['c','cpp']`：vim-cpp-enhanced-highlight、vim-fswitch
- `for: 'markdown'`：vim-markdown、vim-instant-markdown、tabular
- 其余全部保持立即加载（NERDTree/airline/fzf/fugitive/auto-pairs/gutentags/nerdcommenter/tagbar/indent-guides/maktaba/codefmt/glaive）

### 5. 脚本适配

- `30-plugins.sh`：`PluginInstall` → `PlugInstall --sync`（--sync 阻塞至完成，适配无头模式）
- Makefile：`update` 目标 `PluginInstall!` → `PlugUpdate --sync`；删 `tern` 目标（链变为 plugins → help）；.PHONY 同步
- `verify.vim`：新增 `:PlugInstall` 命令存在性检查（插件管理器自检）；ycm_core glob 改 plugged 路径
- `50-ycm.sh`、`05-deps.sh`、`verify.sh`、preflight 逻辑不变（除 50-ycm 的 YCM_DIR）

### 6. 文档

- README：Vundle → vim-plug 描述；make 目标表删 tern 行；YCM 编译路径 bundle→plugged；加「旧 bundle/ 目录可手动删除」说明
- `doc/myvim.txt`：删 tern/javacomplete2 节；插件清单更新；管理器命令改 :PlugInstall/:PlugUpdate/:PlugStatus

## 验证计划

1. 备份并清空 `~/.vim/plugged` 后 `make install` 全量重装，连跑两次幂等，退出码 0
2. `make verify` 全绿（含新增 :PlugInstall 检查）
3. `vim -es` 启动无报错；js/cpp/md 文件分别打开确认延迟加载插件生效（`:scriptnames`）
4. `:help myvim` 可打开
5. brew vim（+python3）下 YCM 声明恢复，`:YcmDebugInfo` 可用（`make ycm` 编译后）
