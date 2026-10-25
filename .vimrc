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
set foldlevelstart=99               " 打开文件时折叠全展开 (99), 不主动折叠
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
Plug 'sainnhe/everforest'          " 首选配色
Plug 'joshdick/onedark.vim'       " 备用: :colorscheme onedark
Plug 'tomasr/molokai'              " 备用: :colorscheme molokai

call plug#end()
filetype plugin indent on
syntax enable
" everforest 背景三档: hard #272e33 最深 / medium 默认 / soft #333c43 最浅(亮)
set background=dark                  " 显式声明, 避免终端探测成 light 导致主题变浅色盘
" 真彩色: Apple Terminal 已实测支持 24 位色; t_8f/t_8b 显式指定转义序列, 不依赖 terminfo
set termguicolors
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
let g:everforest_background = 'soft'
silent! colorscheme everforest               " 必须在 plug#end() 后,主题才在 rtp 中
let g:airline_theme='everforest'    " 状态栏与主题配套

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
  " jdtls: 挂 lombok agent(1.18.48, ~/.vim/lombok.jar, make coding 自动下载), JVM 跟随 brew 默认(jdt.ls 需>=21,
  " 未来 JDK 升级致 jdt.ls 启动异常时再补 --java-executable 钉版本),
  " 显式 -data 按启动目录全路径隔离 workspace(默认按目录名哈希, 同名工程会撞), root_uri 向上找最近 pom.xml
  autocmd User lsp_setup call lsp#register_server(#{
    \ name: 'jdtls',
    \ cmd: ['jdtls',
    \   '--jvm-arg=-javaagent:' . expand('~/.vim/lombok.jar'),
    \   '-data', expand('~/.cache/jdtls-ws/') . substitute(getcwd(), '/', '%', 'g')],
    \ root_uri: {-> lsp#utils#path_to_uri(
    \   lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'pom.xml'))},
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
" Git (vim-fugitive, 映射 \gd 与 LSP 的裸 gd 无冲突)
" ============================================================================
" \gd 当前文件 vs 暂存区, 垂直对照分屏 (等价 git diff)
" 变体手敲: :Gvdiffsplit HEAD → vs 上次提交; 退出关 fugitive 窗格即可,
" ]c/[c 跳 hunk, dp/do 把改动推到对侧/拉回本侧 (vim 原生 diff 键)
nnoremap <leader>gd :Gvdiffsplit<CR>

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
  " 启动时若无文件参数, 自动开 NERDTree（先算 gitignore 隐藏表）
  autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | call s:nerdtree_hide_gitignored() | NERDTree | endif
  " 若 NERDTree 是最后一个窗口, 自动退出 vim
  autocmd BufEnter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
augroup END

" gitignored 文件/目录不进树：构建产物/jar/plugged 与源码平铺是噪音；
" nerdtree-git-plugin 只管标记不管隐藏（ShowIgnored 也只是加个标记字符），
" 故按仓库根跑 git ls-files 生成 NERDTreeIgnore。局限：NERDTreeIgnore 只认
" 文件名不认路径，同名异路径文件会被连带隐藏；非 git 目录得到空表（即默认）
function! s:nerdtree_hide_gitignored() abort
  let l:root = fnamemodify(getcwd(), ':p:h')
  let l:out = systemlist('git -C ' . shellescape(l:root)
        \ . ' ls-files -o -i --exclude-standard --directory 2>/dev/null')
  " 种子: .git 仓库内部件——git 对它整体跳过不走 ignore 规则，ShowHidden=1
  " 时会露出来（dotfiles 仓需要 ShowHidden 看指缀文件，.git 是唯一该藏的）
  let l:pats = ['\.git$']
  for l:f in filter(copy(l:out), 'v:val !~ "^\\s*$"')
    " --directory 输出形如 target/、node_modules/；去尾斜杠做整名匹配
    call add(l:pats, '^' . escape(substitute(l:f, '/$', '', ''), '.*[]~^$\') . '$')
  endfor
  let g:NERDTreeIgnore = l:pats
endfunction
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
nmap <C-n> :call <SID>nerdtree_hide_gitignored()<CR>:NERDTreeToggle<CR>

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
let g:instant_markdown_autostart = 0   " 打开 md 不自动开 preview, 手动: <leader>mp 开 / <leader>ms 关
nnoremap <leader>mp :InstantMarkdownPreview<CR>
nnoremap <leader>ms :InstantMarkdownStop<CR>

" ============================================================================
" Java 语法
" ============================================================================
" Vim 9.2 自带 syntax/java.vim 的 Javadoc 内嵌 markdown 高亮会按 rtp 顺序
" include 到上面的 plasticboy/vim-markdown (其组名体系是 mkd*/html*, 不含
" markdownH1 等), 导致打开 java 文件报 E28. 关闭内嵌特性消音 (java 高亮不受影响).
let g:java_ignore_markdown = 1

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
" Java 依赖类检索 (fzf + vineflower)
" ============================================================================
" <leader>jc  fzf 模糊检索 ~/.m2 全部依赖 jar 里的类, 选中后按三层链打开:
"   层0 缓存命中   ~/.cache/decomp/ 下已有该类 → 直接打开 (零等待)
"   层1 sources包  jar 同目录有 -sources.jar → 解出真源码
"   层2 mvn拉取    mvn dependency:get 按坐标下载 sources.jar (走 settings.xml
"                  镜像, 公司 nexus 也能拉; 20s 超时自动放弃)
"   层3 vineflower 无源码可用 → 反编译 (0.4s, 输出也进缓存)
" 所有层的产物都落在 ~/.cache/decomp/<jar路径sha16>/<包路径>/类名.java
" 依赖: brew install fzf vineflower maven (unzip 系统自带)
" 配置覆盖: g:mavenclasses_index(索引路径) / g:mavenclasses_cache_root(缓存根)
"          g:mavenclasses_sources_download(默认1, 置0 禁止联网只走本地+反编译)
" 重建索引: :MavenClasses! (~5s, 新装依赖后执行)

" jar 路径 → [groupId, artifactId, version, classifier]; 非 ~/.m2 路径返回 []
function! s:MavenCoords(jar) abort
  let l:repo = expand('~/.m2/repository')
  if stridx(a:jar, l:repo . '/') != 0 | return [] | endif
  let l:parts = split(strpart(a:jar, len(l:repo) + 1), '/')
  if len(l:parts) < 4 | return [] | endif
  let l:ver = l:parts[-2]
  let l:art = l:parts[-3]
  let l:group = join(l:parts[0 : -4], '.')
  let l:base = l:art . '-' . l:ver
  let l:fname = l:parts[-1]
  let l:cls = ''
  if l:fname !=# l:base . '.jar' && strpart(l:fname, 0, len(l:base) + 1) ==# l:base . '-'
    let l:cls = strpart(l:fname, len(l:base) + 1, len(l:fname) - len(l:base) - 5)
  endif
  return [l:group, l:art, l:ver, l:cls]
endfunction

" jar 路径 → dependency:get 的 -Dartifact 坐标 (classifier jar 拉 c-sources)
function! s:MavenSourcesArtifact(jar) abort
  let l:c = s:MavenCoords(a:jar)
  if empty(l:c) | return '' | endif
  return join(l:c[0 : 2], ':') . ':jar:' . (empty(l:c[3]) ? 'sources' : l:c[3] . '-sources')
endfunction

" jar 路径 → 同目录 sources jar 路径 (带 classifier 的 jar 也正确推导)
function! s:SourcesJarPath(jar) abort
  return substitute(a:jar, '\.jar$', '-sources.jar', '')
endfunction

" class entry → sources jar 里的 .java entry (内部类归并到外部类)
function! s:SourcesEntry(entry) abort
  return substitute(substitute(a:entry, '\$[^/]*\.class$', '.class', ''),
        \ '\.class$', '.java', '')
endfunction

" (jar, class entry) → 反编译/源码缓存文件路径; 同类多版本 jar 天然隔离
function! s:ClassCachePath(jar, entry) abort
  let l:root = expand(get(g:, 'mavenclasses_cache_root', '~/.cache/decomp'))
  return l:root . '/' . strpart(sha256(a:jar), 0, 16) . '/' . s:SourcesEntry(a:entry)
endfunction

" 生成 ~/.cache/m2classes.txt 索引, 行格式: <class entry><TAB><jar 路径>
function! s:MavenIndexBuild() abort
  let l:idx = expand(get(g:, 'mavenclasses_index', '~/.cache/m2classes.txt'))
  let l:dir = fnamemodify(l:idx, ':h')
  if !isdirectory(l:dir) | call mkdir(l:dir, 'p') | endif
  " 单 jar 列表脚本: 只留 .class 条目, 行尾附加 jar 路径 (fzf --nth=1 只匹配类名)
  let l:helper = l:dir . '/m2classes_listjar.sh'
  call writefile([
        \ '#!/bin/sh',
        \ 'j="$1"',
        \ 'unzip -Z1 "$j" 2>/dev/null | grep ''\.class$'' | awk -v j="$j" ''{print $0 "\t" j}''',
        \ ], l:helper)
  call system('chmod +x ' . shellescape(l:helper))
  redraw | echo '构建 ~/.m2 类索引 (~5s, 仅首次)...'
  call system('find ' . shellescape(expand('~/.m2/repository'))
        \ . ' -name ''*.jar'' ! -name ''*sources*'' ! -name ''*javadoc*'' -print0'
        \ . ' | xargs -0 -P 8 -n 1 ' . shellescape(l:helper)
        \ . ' > ' . shellescape(l:idx) . ' 2>/dev/null')
  redraw | echo ''
  return v:shell_error == 0
endfunction

" mvn 拉取 sources.jar (job_wait 20s 防网络悬挂), 成功与否以文件落地为准
function! s:MvnFetchSources(jar) abort
  if !get(g:, 'mavenclasses_sources_download', 1) || !executable('mvn')
    return 0
  endif
  let l:artifact = s:MavenSourcesArtifact(a:jar)
  if empty(l:artifact) | return 0 | endif
  let l:cwd = tempname()
  call mkdir(l:cwd, 'p')  " 空目录, 避免误读当前工程的 pom.xml
  redraw | echo 'mvn 拉取 ' . l:artifact . ' (最长 20s)...'
  let l:job = job_start(['mvn', '-q', 'dependency:get',
        \ '-Dartifact=' . l:artifact, '-Dtransitive=false'],
        \ {'cwd': l:cwd, 'out_io': 'null', 'err_io': 'null'})
  " Vim 无 job_wait (Neovim 的 jobwait), 轮询 job_status, 20s 上限防网络悬挂
  let l:t0 = reltime()
  while job_status(l:job) ==# 'run' && reltimefloat(reltime(l:t0)) < 20.0
    sleep 50m
  endwhile
  if job_status(l:job) ==# 'run'
    call job_stop(l:job)
  endif
  return filereadable(s:SourcesJarPath(a:jar))
endfunction

function! s:ExtractFromJar(jar, jentry) abort
  let l:out = system('unzip -p ' . shellescape(a:jar) . ' ' . shellescape(a:jentry))
  return (v:shell_error || empty(l:out)) ? '' : l:out
endfunction

function! s:WriteCache(path, content) abort
  let l:dir = fnamemodify(a:path, ':h')
  if !isdirectory(l:dir) | call mkdir(l:dir, 'p') | endif
  call writefile(split(a:content, "\n", 1), a:path)
endfunction

" vineflower 反编译单个类 (内部类归并外部类一起输出), 产物写入缓存路径
function! s:VineflowerDecompile(jar, entry, cachepath) abort
  if !executable('vineflower') | return 0 | endif
  let l:outer = substitute(s:SourcesEntry(a:entry), '\.java$', '.class', '')
  let l:tmp = tempname()
  let l:classfile = l:tmp . '/' . l:outer
  call mkdir(fnamemodify(l:classfile, ':h'), 'p')
  call system('unzip -p ' . shellescape(a:jar) . ' ' . shellescape(l:outer)
        \ . ' > ' . shellescape(l:classfile))
  if v:shell_error | return 0 | endif
  let l:outdir = l:tmp . '/out'
  call mkdir(l:outdir, 'p')
  call system('vineflower --silent ' . shellescape(l:classfile) . ' ' . shellescape(l:outdir))
  if v:shell_error | return 0 | endif
  let l:java = get(glob(l:outdir . '/*.java', 0, 1) + glob(l:outdir . '/**/*.java', 0, 1), 0, '')
  if empty(l:java) | return 0 | endif
  call s:WriteCache(a:cachepath, join(readfile(l:java, 'b'), "\n"))
  return 1
endfunction

" fzf sink: 行格式 <entry><TAB><jar>; 返回 'cache'/'sources'/'mvn'/'vineflower'/''
" 各慢速阶段有 cmdline 进度提示, 打开后回执标明由哪层解析
function! s:MavenClassOpen(line) abort
  let l:parts = split(a:line, "\t")
  if len(l:parts) != 2 || !filereadable(l:parts[1]) | return '' | endif
  let [l:entry, l:jar] = l:parts
  let l:cache = s:ClassCachePath(l:jar, l:entry)
  let l:layer = filereadable(l:cache) ? 'cache' : ''   " 层0 缓存命中
  if empty(l:layer)
    let l:sjar = s:SourcesJarPath(l:jar)
    let l:fetched = 0
    if !filereadable(l:sjar)                          " 层2 mvn 在线拉取(函数内有提示)
      if s:MvnFetchSources(l:jar)
        let l:fetched = 1
      else
        let l:sjar = ''
      endif
    endif
    if !empty(l:sjar) && filereadable(l:sjar)         " 层1 解包 sources jar
      let l:src = s:ExtractFromJar(l:sjar, s:SourcesEntry(l:entry))
      if !empty(l:src)
        call s:WriteCache(l:cache, l:src)
        let l:layer = l:fetched ? 'mvn' : 'sources'
      endif
    endif
    if empty(l:layer)                                 " 层3 反编译兜底 (~1s)
      redraw | echo 'MavenClasses: vineflower 反编译中...'
      if s:VineflowerDecompile(l:jar, l:entry, l:cache)
        let l:layer = 'vineflower'
      endif
    endif
  endif
  if empty(l:layer)
    redraw | echoerr 'MavenClasses: 无法获取 ' . l:entry . ' (' . l:jar . ')'
    return ''
  endif
  " &modified 时 :edit 抛 E37 (fzf.vim 的 s:callback 会接住并 echoerr 成红字
  " 告警, 且目标文件开不出来), 此时改在新 split 打开, 不动用户未保存的 buffer
  if &modified
    execute 'split' fnameescape(l:cache)
  else
    execute 'edit' fnameescape(l:cache)
  endif
  let l:tag = {'cache': '缓存', 'sources': 'sources.jar', 'mvn': 'mvn拉取',
        \ 'vineflower': '反编译'}[l:layer]
  redraw | echo 'MavenClasses[' . l:tag . '] ' . l:cache
  return l:layer
endfunction

" fzf#run 参数字典。注意: 本机新版 fzf 插件 (junegunn/fzf ≥0.48, vim runtime
" 并入主仓库) 的 s:callback 只分发 sink/sink*/sinklist; 老版 fzf.vim 的
" sinkfunction 键会被静默无视 → 选中后无任何反应。sink 直接传 Funcref 即可。
function! s:MavenClassesRunDict() abort
  let l:idx = expand(get(g:, 'mavenclasses_index', '~/.cache/m2classes.txt'))
  return {
        \ 'source': 'cat ' . shellescape(l:idx),
        \ 'sink': function('s:MavenClassOpen'),
        \ 'options': ['--prompt', 'MavenClasses> ',
        \             '--delimiter', "\t", '--nth', '1',
        \             '--header', 'enter 打开: 源码缓存→sources.jar→mvn拉取→反编译'],
        \ 'down': '45%'}
endfunction

function! s:MavenClasses(bang) abort
  let l:idx = expand(get(g:, 'mavenclasses_index', '~/.cache/m2classes.txt'))
  if a:bang || !filereadable(l:idx)
    call s:MavenIndexBuild()
  endif
  if !exists('*fzf#run')
    echoerr 'fzf 插件未加载, 运行 make plugins'
    return
  endif
  call fzf#run(s:MavenClassesRunDict())
endfunction

if executable('fzf') && executable('unzip') && executable('vineflower')
  command! -bang MavenClasses call s:MavenClasses(<bang>0)
  nnoremap <leader>jc :MavenClasses<CR>
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
" g:claude_cmd        交互式终端启动命令 (默认 'claude', 用于 <leader>ai)
" g:claude_pipe_cmd   one-shot pipe 命令 (默认 'claude', 用于 <leader>ab/aq)
"                       若 pipe 与交互命令不同, 可分别设置
" g:claude_vsplit_min <leader>ai 竖开阈值: &columns >= 此值时右侧 vsplit, 否则底部 20 行
"                       (默认 160; 竖开宽度 = min(90, &columns/2))
"
" 改写示例 (在 call plug#begin() 之前 set):
"   let g:claude_cmd = 'claude'                    " 直调 claude 二进制
"   let g:claude_cmd = 'zsh -ic claude'            " 复用 zsh 函数 (加载 .zshrc)
"   let g:claude_pipe_cmd = 'claude'               " pipe 模式用裸 claude
"
"   <leader>ai  normal: 打开 Claude Code 终端 (用 g:claude_cmd), 宽屏右侧竖开/窄屏底部横开
"   <leader>ab  visual: 选区 → Claude 改写 (原地替换 buffer, 失败可 u 撤销)
"                例: 选中代码 → <leader>ab → 输入 "convert to async/await" → Enter
"   <leader>aq  visual: 选区 → Claude 查询 (输出到终端, 不改 buffer)
"                例: 选中代码 → <leader>aq → 输入 "explain this" → Enter
let g:claude_cmd = get(g:, 'claude_cmd', 'zsh -ic claude')
let g:claude_pipe_cmd = get(g:, 'claude_pipe_cmd', 'claude')
let g:claude_vsplit_min = get(g:, 'claude_vsplit_min', 160)

" 按传入总列数返回 split 命令: 宽屏 (>= g:claude_vsplit_min) 右侧竖开, 窄屏底部横开
function! s:ClaudeSplitCmd(cols) abort
  if a:cols >= g:claude_vsplit_min
    return 'botright vertical ' . min([90, a:cols / 2]) . 'vsplit'
  endif
  return 'botright 20split'
endfunction

function! s:ClaudeAI() abort
  " ++curwin: 让 :term 在当前窗口打开 (替换 :split 创建的 buffer 副本), 否则会有重复窗口
  execute s:ClaudeSplitCmd(&columns) . ' | term ++curwin ' . g:claude_cmd
endfunction

if executable('claude')
  nnoremap <leader>ai :call <SID>ClaudeAI()<CR>
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
