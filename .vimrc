imap jk <Esc>

" Bind K in visual mode to move the selection up
vnoremap K :m '<-2<CR>gv=gv

" Bind J in visual mode to move the selection down
vnoremap J :m '>+1<CR>gv=gv

set clipboard=unnamedplus

" Bind Shift + H to move to the start of the line in normal mode
nnoremap <S-h> ^

" Bind Shift + L to move to the end of the line in normal mode
nnoremap <S-l> $
