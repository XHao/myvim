" ============================================================================
" 基础设置
" ============================================================================
set nu
set cursorline                       " 高亮当前行
set cursorcolumn                     " 高亮当前列
set shiftwidth=4
set tabstop=4
set expandtab                        " tab → spaces
set hlsearch                         " 高亮搜索结果
set incsearch                        " 增量搜索
set ignorecase                       " 搜索忽略大小写
set cindent                          " C 风格缩进
set foldenable
set foldmethod=syntax
set foldcolumn=0
set foldlevel=1
set backspace=indent,eol,start       " backspace 可删行首/缩进
set mouse=a
set wildmenu                         " 命令行补全菜单
" nocompatible 在 -E -s 模式 source vimrc 时必需,否则 \ 行续行报 E10
" (vim -E -s 启动时未加载 vimrc,默认 compatible,\ 续行失效)
set nocompatible

" ============================================================================
" 插件管理 (vim-plug)
" ============================================================================
call plug#begin('~/.vim/plugged')

" 补全/片段 (ultisnips 需 vim +python3)
if has('python3')
  Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'
endif

" LSP + Go (替代 YCM,无需编译)
Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'fatih/vim-go'

" 文件/跳转
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'majutsushi/tagbar'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'ludovicchabant/vim-gutentags'
Plug 'derekwyatt/vim-fswitch', { 'for': ['c', 'cpp'] }

" Git
Plug 'tpope/vim-fugitive'

" 编辑增强
Plug 'jiangmiao/auto-pairs'
Plug 'scrooloose/nerdcommenter'
Plug 'godlygeek/tabular', { 'for': 'markdown' }

" 语言支持 (按需懒加载)
Plug 'octol/vim-cpp-enhanced-highlight', { 'for': ['c', 'cpp'] }
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'moll/vim-node', { 'for': 'javascript' }
Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }
Plug 'suan/vim-instant-markdown', { 'for': 'markdown' }

" 界面/格式化
Plug 'vim-airline/vim-airline'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'google/vim-maktaba'
Plug 'google/vim-codefmt'
Plug 'google/vim-glaive'
Plug 'tomasr/molokai'              " 配色方案(vim-plug 管理, :PlugUpdate 自动更新)

call plug#end()
filetype plugin indent on
syntax enable
colorscheme molokai                  " 必须在 plug#end() 后,molokai 才在 rtp 中

" ============================================================================
" LSP (vim-lsp + asyncomplete + pyright/gopls/jdtls/clangd)
" ============================================================================
" server 注册 (各 server 由 make coding 装, clangd 系统自带)
augroup lsp_setup
  autocmd!
  autocmd User lsp_setup call lsp#register_server(#{
    \ name: 'clangd',
    \ cmd: ['clangd', '--background-index', '--clang-tidy'],
    \ allowlist: ['c', 'cpp', 'objc', 'objcpp']})
  autocmd User lsp_setup call lsp#register_server(#{
    \ name: 'pyright',
    \ cmd: ['pyright-langserver', '--stdio'],
    \ allowlist: ['python']})
  autocmd User lsp_setup call lsp#register_server(#{
    \ name: 'gopls',
    \ cmd: ['gopls', 'serve'],
    \ allowlist: ['go', 'gomod', 'gowork']})
  autocmd User lsp_setup call lsp#register_server(#{
    \ name: 'jdtls',
    \ cmd: ['jdtls'],
    \ allowlist: ['java']})
augroup END

" vim-lsp 由 plugin/lsp.vim 在 VimEnter 时自动调 lsp#enable() (g:lsp_auto_enable=1)
" 不要在此手动调用 — plugin/lsp.vim 还未 source, g:lsp_log_file 等变量未定义会报错

" vim-go 用 gopls 作 LSP 来源
let g:go_def_mode = 'gopls'
let g:go_gopls_enabled = 1

" 保存时格式化 (vim-lsp sync format)
let g:lsp_format_sync_timeout = 1000

" asyncomplete 自动 popup (打字时弹 LSP 补全列表)
" asyncomplete-lsp.vim 监听 User lsp_server_init 自动注册 source, 无需手动 autocmd
let g:asyncomplete_auto_popup = 1

" LSP 跳转键 (coc.nvim 社区主流风格)
" 注: gd/gD/gi/gr 是 vim 原生键, 被 LSP 接管后失去原功能:
"   gd 原=local definition (ctags), 现=LSP 跳定义
"   gD 原=global definition, 现=LSP 跳声明
"   gi 原=跳到上次 insert 位置, 现=LSP 跳实现 ← 失去
"   gr 原=replace operator (vim9), 现=LSP 查引用 ← 失去
nnoremap gd            :LspDefinition<CR>
nnoremap gD            :LspDeclaration<CR>
nnoremap gi            :LspImplementation<CR>
nnoremap gr            :LspReferences<CR>
nnoremap <leader>ca   :LspCodeAction<CR>
nnoremap <leader>rn   :LspRename<CR>
nnoremap K             :LspHover<CR>
nnoremap [d            :LspPreviousDiagnostic<CR>
nnoremap ]d            :LspNextDiagnostic<CR>
nnoremap <leader>ds   :LspDocumentSymbol<CR>
nnoremap <leader>ws   :LspWorkspaceSymbol<CR>

" ============================================================================
" 代码格式化 (vim-codefmt + clang-format)
" ============================================================================
augroup autoformat_settings
  autocmd FileType c,cpp,proto,javascript AutoFormatBuffer clang-format
augroup END

" ============================================================================
" NERDTree (文件树)
" ============================================================================
let NERDTreeShowHidden = 1
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'
augroup NERDTree_autocmds
  autocmd!
  autocmd StdinReadPre * let s:std_in=1
  " 启动时若无文件参数, 自动开 NERDTree
  autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
  " 若 NERDTree 是最后一个窗口, 自动退出 vim
  autocmd BufEnter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
augroup END
let g:NERDTreeGitStatusIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ "Unknown"   : "?"
    \ }
nmap <C-n> :NERDTreeToggle<CR>

" ============================================================================
" Tagbar (符号大纲)
" ============================================================================
let tagbar_width = 32
let g:tagbar_compact = 1
let g:tagbar_type_cpp = {
    \ 'kinds' : [
    \ 'c:classes:0:1',
    \ 'd:macros:0:1',
    \ 'e:enumerators:0:0',
    \ 'f:functions:0:1',
    \ 'g:enumeration:0:1',
    \ 'l:local:0:1',
    \ 'm:members:0:1',
    \ 'n:namespaces:0:1',
    \ 'p:functions_prototypes:0:1',
    \ 's:structs:0:1',
    \ 't:typedefs:0:1',
    \ 'u:unions:0:1',
    \ 'v:global:0:1',
    \ 'x:external:0:1'
    \ ],
    \ 'sro'        : '::',
    \ 'kind2scope' : {
    \ 'g' : 'enum',
    \ 'n' : 'namespace',
    \ 'c' : 'class',
    \ 's' : 'struct',
    \ 'u' : 'union'
    \ },
    \ 'scope2kind' : {
    \ 'enum'      : 'g',
    \ 'namespace' : 'n',
    \ 'class'     : 'c',
    \ 'struct'    : 's',
    \ 'union'     : 'u'
    \ }
    \ }
nmap <F8> :TagbarToggle<CR>

" ============================================================================
" NERDCommenter (注释)
" ============================================================================
let g:NERDSpaceDelims = 1                  " 注释符后加空格
let g:NERDCompactSexyComs = 1              " 紧凑多行注释
let g:NERDDefaultAlign = 'left'            " 左对齐
let g:NERDAltDelims_java = 1               " Java 用替代注释符
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }
let g:NERDCommentEmptyLines = 1            " 允许注释空行
let g:NERDTrimTrailingWhitespace = 1       " 取消注释时修剪尾空格
let g:NERDToggleCheckAllLines = 1

" ============================================================================
" UltiSnips (代码片段)
" ============================================================================
" UltiSnipsSnippetDirectories 不显式设置 — 用默认 ["UltiSnips"]
" vim-snippets 同时提供 snippets/ (snipMate) 和 UltiSnips/ (原生) 两套,
" 默认目录自动找到 plugged/vim-snippets/UltiSnips/*.snippets
" 不要设为 ["snippets"] — 这是 snipMate 保留名, 会触发 UltiSnips 报错
let g:UltiSnipsExpandTrigger = "<leader><tab>"
let g:UltiSnipsJumpForwardTrigger = "<leader><tab>"
let g:UltiSnipsJumpBackwardTrigger = "<leader><s-tab>"
let g:UltiSnipsEditSplit = "vertical"

" ============================================================================
" vim-airline (状态栏)
" ============================================================================
set laststatus=2
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#whitespace#enabled = 0
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'

" ============================================================================
" vim-markdown
" ============================================================================
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_json_frontmatter = 1
let g:vim_markdown_toc_autofit = 1
let g:vim_markdown_fenced_languages = ['java=java', 'c++=cpp', 'viml=vim', 'bash=sh', 'ini=dosini']
let g:vim_markdown_new_list_item_indent = 2
let g:instant_markdown_slow = 1

" ============================================================================
" vim-indent-guides (缩进参考线)
" ============================================================================
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_start_level = 2
let g:indent_guides_guide_size = 1

" ============================================================================
" fzf (模糊搜索, 需 brew install fzf ripgrep)
" ============================================================================
" 无二进制时不映射, 避免 fzf 插件弹出阻塞式下载提示
if executable('fzf')
  nnoremap <C-p> :Files<CR>
endif
if executable('rg')
  nnoremap <leader>rg :Rg<CR>
endif

" ============================================================================
" vim-fswitch (.cpp ↔ .h)
" ============================================================================
nmap <silent> <Leader>swi :FSHere<CR>

" ============================================================================
" Claude Code (AI coding agent)
" ============================================================================
" 需 npm install -g @anthropic-ai/claude-code 或自定义启动器
" 用 <leader>a* 前缀避开 NERDCommenter 的 <leader>c* 命名空间
"
" g:claude_cmd        交互式终端启动命令 (默认 'mc --code', 用于 <leader>ai)
" g:claude_pipe_cmd   one-shot pipe 命令 (默认 'mc --code', 用于 <leader>ab/aq)
"                       若 pipe 与交互命令不同, 可分别设置
"
" 改写示例 (在 call plug#begin() 之前 set):
"   let g:claude_cmd = 'claude'                    " 直调 claude 二进制
"   let g:claude_cmd = 'zsh -ic claude'            " 复用 zsh 函数 (加载 .zshrc)
"   let g:claude_pipe_cmd = 'mc'                    " pipe 模式用裸 mc
"
"   <leader>ai  normal: 底部 20 行 split 打开 Claude Code 终端 (用 g:claude_cmd)
"   <leader>ab  visual: 选区 → Claude 改写 (原地替换 buffer, 失败可 u 撤销)
"                例: 选中代码 → <leader>ab → 输入 "convert to async/await" → Enter
"   <leader>aq  visual: 选区 → Claude 查询 (输出到终端, 不改 buffer)
"                例: 选中代码 → <leader>aq → 输入 "explain this" → Enter
let g:claude_cmd = get(g:, 'claude_cmd', 'mc --code')
let g:claude_pipe_cmd = get(g:, 'claude_pipe_cmd', 'mc --code')

if executable('claude')
  " ++curwin: 让 :term 在当前窗口打开 (替换 :split 创建的 buffer 副本), 否则会有重复窗口
  execute 'nnoremap <leader>ai :botright 20split <bar> term ++curwin ' . g:claude_cmd . '<CR>'
  execute 'xnoremap <leader>ab :' . "'<,'>!" . g:claude_pipe_cmd
  execute 'xnoremap <leader>aq :' . "'<,'>w !" . g:claude_pipe_cmd
endif

" ============================================================================
" vim-gutentags (自动维护 ctags)
" ============================================================================
let g:gutentags_cache_dir = expand('~/.cache/tags')
let g:gutentags_project_root = ['.git']
call mkdir(g:gutentags_cache_dir, 'p')
if !executable('ctags') || system('ctags --version') !~? 'exuberant\|universal'
  let g:gutentags_enabled = 0
endif

" ============================================================================
" 折叠
" ============================================================================
" <space> 在闭合 fold 上 zo 展开, 否则 zc 折叠
nnoremap <space> @=((foldclosed(line('.')) < 0) ? 'zc' : 'zo')<CR>
