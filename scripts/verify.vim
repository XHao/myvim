" 插件能力冒烟测试：由 make verify 以 vim -E -s -S 执行
" 注意：-E -s 模式不会自动加载 vimrc，也不会自动 source plugin/*.vim，
" 必须显式 source vimrc 并 runtime! plugin/**/*.vim 才能让插件命令注册。
" echom 在 -s 模式不会输出到 stdout，所以报告累加进 s:lines，
" 最后用 :!cat 输出到 stdout，并用 :cquit 反映退出码。
" FAIL → :cquit（退出码非 0）；WARN 不阻塞
" 约定：.vimrc 新增插件时在此登记一行检查

source $HOME/.vimrc
runtime! plugin/**/*.vim

let s:fail = 0
let s:lines = []

function! s:report(level, name, hint) abort
  if a:level ==# 'PASS'
    let l:line = '[PASS] ' . a:name
  elseif a:level ==# 'WARN'
    let l:line = '[WARN] ' . a:name . ' → ' . a:hint
  else
    let l:line = '[FAIL] ' . a:name . ' → ' . a:hint
    let s:fail = 1
  endif
  call add(s:lines, l:line)
  " 仍 echom 一份，便于 :messages 调试
  echom l:line
endfunction

function! s:check_cmd(cmd, hint) abort
  if exists(':' . a:cmd) == 2
    call s:report('PASS', ':' . a:cmd, '')
  else
    call s:report('FAIL', ':' . a:cmd, a:hint)
  endif
endfunction

call s:check_cmd('PlugInstall', 'vim-plug 未加载？检查 autoload/plug.vim')
call s:check_cmd('NERDTreeToggle', '运行 make plugins')
call s:check_cmd('TagbarToggle', '运行 make plugins')
call s:check_cmd('Files', 'junegunn/fzf 未装上？运行 make plugins')
call s:check_cmd('Rg', 'fzf.vim 未装上？运行 make plugins')
call s:check_cmd('Git', 'vim-fugitive 未装上？运行 make plugins')
call s:check_cmd('AutoFormatBuffer', 'vim-codefmt 未装上？运行 make plugins')
" GutentagsUpdate 是 buffer-local 命令，仅在打开项目缓冲区时注册，
" 在 -E -s 无头模式下不可用。改为检查插件已加载（g:gutentags_enabled 存在）。
if exists('g:gutentags_enabled')
  call s:report('PASS', 'vim-gutentags 插件已加载', '')
else
  call s:report('FAIL', 'vim-gutentags 插件', '运行 make plugins')
endif

try
  colorscheme molokai
  call s:report('PASS', 'colorscheme molokai', '')
catch
  call s:report('FAIL', 'colorscheme molokai', '检查 colors/molokai.vim 是否存在')
endtry

if has('python3')
  call s:report('PASS', 'vim +python3', '')
  if empty(glob(expand('~/.vim/plugged/YouCompleteMe/third_party/ycmd/ycm_core*')))
    call s:report('WARN', 'YCM 未编译', 'make ycm')
  else
    call s:report('PASS', 'YCM 已编译', '')
  endif
else
  call s:report('WARN', 'vim 无 python3，YCM/UltiSnips 已按条件跳过', 'brew install vim')
endif

let s:tagdir = expand('~/.cache/tags')
if !isdirectory(s:tagdir)
  call mkdir(s:tagdir, 'p')
endif
if filewritable(s:tagdir) == 2
  call s:report('PASS', 'gutentags 缓存目录可写', '')
else
  call s:report('WARN', 'gutentags 缓存目录不可写', 'mkdir -p ~/.cache/tags')
endif

try
  execute 'help myvim'
  helpclose
  call s:report('PASS', ':help myvim', '')
catch
  call s:report('WARN', ':help myvim 不可用', '运行 make help')
endtry

" 把累计报告输出到 stdout（-s 模式下 echom 不进 stdout，必须借 :! 打印）
let s:reportfile = tempname()
call writefile(s:lines, s:reportfile)
execute '!' . 'cat ' . shellescape(s:reportfile)
call delete(s:reportfile)

if s:fail
  cquit 1
endif
quit
