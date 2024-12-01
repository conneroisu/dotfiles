" Obsidian Vimrc for Conner Ohnesorge

" Exit insert mode with jkjkjkjkjjkjkjkjjkjk
imap jk <Esc>
" Exit insert mode with kj
imap kj <Esc>

" Surround text with triple quotes making codeblock 
exmap surround_codeblock surround ``` ```
exmap surround_wikilink surround [[ ]]
exmap surround_centered surround <center> </center>

exmap flashcard obcommand auto-anki:export-current-file-to-anki
nmap \fc :flashcard


exmap opensugar obcommand sugar:open-sugar-view
nmap \m :opensugar
exmap savesugar obcommand sugar:save-sugar-view
nmap \s :savesugar
exmap reloadsugar sugar:update-sugar-view
nmap <C-l> :reloadsugar
exmap selectsugar obcommand sugar:select-sugar-entry
nmap <CR> :selectsugar
" map auto-anki:export-current-file-to-anki to ctrl + auto-anki
exmap autoanki obcommand auto-anki:export-current-file-to-anki
nmap \fc :autoanki

" map auto-anki:export-current-selection-to-anki to ctrl + shift + auto-anki
" 
" map jump anywhere command
exmap jump obcommand mrj-jump-to-link:activate-jump-to-anywhere
" map jump anywhere command to ctrl + f
imap jj :jump


" exmapping for centered math mathjax
exmap surround_mathjax surround $$ $$

" Map Shift + h to beginning of the line 
" Map Shift + l to the end of the line
nmap H ^ 
nmap L $

" yank to the system clipboard 
set clipboard=unnamed 


" bind leader + c + f to fix current selection in visual lmode 
exmap fixselection obcommand copilot:fix-grammar-prompt
vmap \cf :fixselection

"Emulate folding within obsidian 
exmap togglefold obcommand editor:toggle-fold 

nmap zo :togglefold
" map ff to surround text with triple backticks
map ff :surround_codeblock
map mm :surround_mathjax
" map ctrl + w to surround current line with wikilink for each line
map <C-w> :surround_wikilink
" TODO: need to add vertical spli
" TODO: need to add a sugar rush command mapping to leader m 

