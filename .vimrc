set nu
colorscheme molokai 
" hight line and column
set cursorline
set cursorcolumn
set shiftwidth=4
set tabstop=4
set expandtab
set hlsearch
set cindent 
set foldenable
set foldmethod=syntax
set foldcolumn=0 
set backspace=indent,eol,start
setlocal foldlevel=1
set mouse=a
set ignorecase
set incsearch
set wildmenu


set nocompatible              " be iMproved, required

" vim-plug 插件管理（plug.vim 已 vendor 在 ~/.vim/autoload/）
call plug#begin('~/.vim/plugged')

" ultisnips（需 vim +python3，否则跳过声明）
if has('python3')
  Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'
endif

" vim-lsp + asynccomplete + vim-go（全 LSP 架构，替代 YCM）
Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'fatih/vim-go'

Plug 'vim-airline/vim-airline'
Plug 'moll/vim-node', { 'for': 'javascript' }
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'godlygeek/tabular', { 'for': 'markdown' }
Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }
Plug 'suan/vim-instant-markdown', { 'for': 'markdown' }
Plug 'majutsushi/tagbar'
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
" c++ syntax
Plug 'octol/vim-cpp-enhanced-highlight', { 'for': ['c', 'cpp'] }
Plug 'nathanaelkane/vim-indent-guides'
Plug 'derekwyatt/vim-fswitch', { 'for': ['c', 'cpp'] }
" Add maktaba and codefmt to the runtimepath.
" (The latter must be installed before it can be used.)
Plug 'google/vim-maktaba'
Plug 'google/vim-codefmt'
" Also add Glaive, which is used to configure codefmt's maktaba flags. See
" `:help :Glaive` for usage.
Plug 'google/vim-glaive'

" fzf 模糊搜索（需 brew install fzf ripgrep）
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
" git
Plug 'tpope/vim-fugitive'
" 括号自动配对
Plug 'jiangmiao/auto-pairs'
" 自动维护 ctags
Plug 'ludovicchabant/vim-gutentags'

Plug 'scrooloose/nerdcommenter'

call plug#end()            " required

" vim-lsp server 注册（各 server 由 make coding 装，clangd 系统自带）
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

" vim-lsp 由 plugin/lsp.vim 在 VimEnter 时自动调用 lsp#enable()（g:lsp_auto_enable=1）
" 不要在此手动调用 —— plugin/lsp.vim 还未 source, g:lsp_log_file 等变量未定义会报错

" vim-go 配置（与 vim-lsp 协作，gopls 作 LSP 来源）
let g:go_def_mode = 'gopls'
let g:go_gopls_enabled = 1

" 保存时格式化（vim-lsp sync format）
let g:lsp_format_sync_timeout = 1000

filetype plugin indent on  " required


augroup autoformat_settings
  autocmd FileType c,cpp,proto,javascript AutoFormatBuffer clang-format
augroup END

syntax enable
syntax on



" airline config
set laststatus=2
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#whitespace#enabled = 0
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'

" markdown config
let g:vim_markdown_folding_disabled=1
let g:vim_markdown_frontmatter=1
let g:vim_markdown_json_frontmatter = 1
let g:vim_markdown_toc_autofit = 1
let g:vim_markdown_fenced_languages = ['java=java', 'c++=cpp', 'viml=vim', 'bash=sh', 'ini=dosini']
let g:vim_markdown_new_list_item_indent = 2
let g:instant_markdown_slow = 1

" https://github.com/justmao945/vim-clang
let g:clang_c_options = '-std=gnu11'
let g:clang_cpp_options = '-std=c++11 -stdlib=libc++'
let g:clang_compilation_database = './build'

" nerd tree
let NERDTreeShowHidden=1
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
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

" vim intent
let g:indent_guides_enable_on_vim_startup=1
let g:indent_guides_start_level=2
let g:indent_guides_guide_size=1

" Trigger configuration（<leader><tab> 展开/跳片段）
let g:UltiSnipsExpandTrigger="<leader><tab>"
let g:UltiSnipsJumpForwardTrigger="<leader><tab>"
let g:UltiSnipsJumpBackwardTrigger="<leader><s-tab>"
let g:UltiSnipsSnippetDirectories=["mysnippets"]


" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"
" 设置 tagbar 子窗口的位置出现在主编辑区的左边 
" let tagbar_left=1 
" 设置标签子窗口的宽度 
let tagbar_width=32 
" tagbar 子窗口中不显示冗余帮助信息 
let g:tagbar_compact=1
" 设置 ctags 对哪些代码标识符生成标签
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

" common nmap
nnoremap <space> @=((foldclosed(line('.')) < 0) ? 'zc' : 'zo')<CR>
nmap <C-t> :TagbarToggle<CR>
nmap <C-n> :NERDTreeToggle<CR>

" LSP 通用键绑定（vim-lsp，替代 YCM 的 YcmCompleter）
nnoremap <leader>jd  :LspDefinition<CR>
nnoremap <leader>jc  :LspDeclaration<CR>
nnoremap <leader>ji  :LspImplementation<CR>
nnoremap <leader>jr  :LspReferences<CR>
nnoremap <leader>ca  :LspCodeAction<CR>
nnoremap <leader>rn  :LspRename<CR>
nnoremap K           :LspHover<CR>
nnoremap [d          :LspPreviousDiagnostic<CR>
nnoremap ]d          :LspNextDiagnostic<CR>
nnoremap <leader>dl  :LspDocumentSymbol<CR>
nnoremap <leader>wl  :LspWorkspaceSymbol<CR>

" .cpp <-> .h, plugin vim-fswitch
nmap <silent> <Leader>swi :FSHere<cr>

" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1
" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1
" Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'
" Set a language to use its alternate delimiters by default
let g:NERDAltDelims_java = 1
" Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }
" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1
" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1
" Enable NERDCommenterToggle to check all selected lines is commented or not
let g:NERDToggleCheckAllLines = 1

" fzf（无二进制时不映射，避免 fzf 插件弹出阻塞式下载提示）
if executable('fzf')
  nnoremap <C-p> :Files<CR>
endif
if executable('rg')
  nnoremap <leader>rg :Rg<CR>
endif

" gutentags（BSD ctags 不支持 --recurse，检测到不兼容则禁用）
let g:gutentags_cache_dir = expand('~/.cache/tags')
let g:gutentags_project_root = ['.git']
call mkdir(g:gutentags_cache_dir, 'p')
if !executable('ctags') || system('ctags --version') !~? 'exuberant\|universal'
  let g:gutentags_enabled = 0
endif
