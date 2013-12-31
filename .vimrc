set tabstop=4		" Number of spaces for the tab character.
set vb t_vb=		" Stop vi(m) from beeping. Flash screen instead.
set ruler			" Ensure the ruler (status line) is always enabled.
set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%)

set shiftwidth=4	" Number of spaces to auto indent.
set number			" Enable line numbers
set encoding=utf-8

syntax on			" Enable syntax highlighting.
filetype on			" Filetype detection
set background=dark
set t_Co=256		" Tell vi(m) we have 256 colors.

if version >= 700
	colorscheme vim-colors	
endif
