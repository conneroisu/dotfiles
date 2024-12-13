eval "$(zellij setup --generate-auto-start zsh)"
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
fi
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
# Defines the characters that zsh considers part of a word (^W)
WORDCHARS='*?[]~=&;!#$%^(){}<>,|`'
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups hist_save_no_dups hist_ignore_dups hist_reduce_blanks hist_find_no_dups
alias cf='cd $(find . -type d -path "./.git" -prune -o -type d -print | fzf --reverse --preview "ls --color {}")'
alias nvimf='nvim $(fzf --preview "bat --color=always {}")'

# eval "$(goenv init -)" # TODO: Remove this once moved to nixos
eval "$(fzf --zsh)"
eval "$(atuin init zsh)"
eval "$(zoxide init zsh --cmd cd)"
eval "$(turso completion zsh)"
eval "$(starship init zsh)"
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
zi load Aloxaf/fzf-tab
zi load jeffreytse/zsh-vi-mode

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Noncase-sensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "\$\{(s.:.)LS_COLORS\}"
zstyle ':completion:*' menu no

# bun completions
[ -s "/home/connerohnesorge/.bun/_bun" ] && source "/home/connerohnesorge/.bun/_bun"

command_not_found_handler() {
    local cmd="$1"
    local packages

    # Use nix-locate to find packages containing this command.
    # `nix-locate` is often used with some filtering options, e.g.:
    # nix-locate -w "$cmd" 
    # If your system differs, adjust accordingly.
    packages=$(rippkgs -i ~/dotfiles/rippkgs-index.sqlite "$cmd")

    if [[ -z "$packages" ]]; then
        echo "Command not found: $cmd"
        return 127
    fi

    echo "The command '$cmd' was not found, but the following packages from Nix might provide it:"
    echo "$packages"

    echo "Fetching more info on these packages using rippkgs..."
    echo "====================================================="

    # Returning a non-zero status code, assuming not installed
    return 127
}
