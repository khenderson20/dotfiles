"~/.vimrc file (a stub made by the installer sources this one)
set nocompatible
set encoding=utf-8
set tabstop=2       " Number of spaces that a <Tab> in the file counts for
set shiftwidth=2    " Number of spaces to use for each step of <auto>indent
set expandtab       " Convert tabs to spaces
syntax on           " Syntax Highlighting
if has('termguicolors')
  set termguicolors
endif
set background=dark " set background
" Solarized if installed, otherwise vim's built-in default (no error)
silent! colorscheme solarized
" Enable line numbers and relative line numbers
set number
" Enable auto-indentation and smart indentation
set autoindent
set smartindent
filetype indent on
" Disable line wrapping
set nowrap
" Enable search highlighting and incremental search
set hlsearch
set incsearch
set showmatch
" Enable clipboard integration (unnamedplus: Linux X11/Wayland,
" unnamed: macOS and Windows)
if has('clipboard')
  set clipboard^=unnamed,unnamedplus
endif
" Always show the status line
set laststatus=2
" Custom status line with file type and encoding
set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [POS=%l,%v][%p%%]\ [LEN=%L]
set list
" Customize the display of hidden characters
set listchars=tab:»·,trail:·,extends:>,precedes:<,nbsp:␣
highlight SpecialKey ctermfg=gray
highlight NonText ctermfg=gray
