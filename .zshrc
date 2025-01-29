eval "$(zellij setup --generate-auto-start zsh)"

autoload -Uz compinit && compinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

export BUN_INSTALL="$HOME/.bun"
export FLYCTL_INSTALL="/home/connerohnesorge/.fly"
export GOPATH="$HOME/.go"
export PATH="$HOME/.cargo/bin:$PATH"
path=(
    $HOME/.cargo/bin
    $BUN_INSTALL/bin
    $HOME/zig
    $HOME/.local/bin
    $HOME/flutter/bin
    $GOROOT/bin
    $GOPATH/bin
    $FLYCTL_INSTALL/bin
    /home/connerohnesorge/.turso
    /home/connerohnesorge/.config/herd-lite/bin
    /user/local/bin/
    $path
)
export PATH=$PATH:path

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export NIX_PATH=darwin=$HOME/.nix-defexpr/darwin:darwin-config=$HOME/.nixpkgs/darwin-configuration.nix:$NIX_PATH
fi
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
# Defines the characters that zsh considers part of a word (^W)
WORDCHARS='*?[]~=&;!#$%^(){}<>,|`'
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups hist_save_no_dups hist_ignore_dups hist_reduce_blanks hist_find_no_dups
# alias cf='cd $(find . -type d -path "./.git" -prune -o -type d -print | fzf --reverse --preview "ls --color {}")'
alias cf='cd $(find . -type d -path "./.git" -prune -o -type d -not -path "*/\.*" -print | fzf --reverse --preview "ls --color {}")'
alias nvimf='nvim $(fzf --preview "bat --color=always {}")'

eval "$(fzf --zsh)"
eval "$(atuin init zsh)"
eval "$(zoxide init zsh --cmd cd)"
eval "$(starship init zsh)"
eval "$(turso completion zsh)"
eval "$(fly completion zsh)"

export LD_LIBRARY_PATH=/usr/local/lib64/:$LD_LIBRARY_PATH
export PHP_INI_SCAN_DIR="/home/connerohnesorge/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"

# Load a few important annexes, without Turbo
zi light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust


zi light zsh-users/zsh-autosuggestions
zi load zsh-users/zsh-completions
zi load zsh-users/zsh-syntax-highlighting
zi load nix-community/nix-zsh-completions
zi load Aloxaf/fzf-tab
zi load jeffreytse/zsh-vi-mode

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Noncase-sensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "\$\{(s.:.)LS_COLORS\}"
zstyle ':completion:*' menu no
alias latest='git add . && git commit -m "latest" && git push'
