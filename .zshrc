autoload -Uz compinit && compinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"
export ANTHROPIC_LOG=error
export BUN_INSTALL="$HOME/.bun"
export PATH="$HOME/.cargo/bin:$PATH"
export CLAUDE_CODE_ENABLE_TELEMETRY="0"
path=(
    $HOME/.cargo/bin
    $BUN_INSTALL/bin
    $path
)
export PATH=$PATH:$path

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
# Defines the characters that zsh considers part of a word (^W)
WORDCHARS='*?[]~=&;!#$%^(){}<>,|`'
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups hist_save_no_dups hist_ignore_dups hist_reduce_blanks hist_find_no_dups

eval "$(fzf --zsh)"
eval "$(atuin init zsh)"

if command -v zoxide &>/dev/null && [[ "$CLAUDECODE" != "1" ]]; then
  eval "$(zoxide init --cmd cd zsh)"
  
  # Ensure __zoxide_z function exists
  if ! type __zoxide_z &>/dev/null; then
    function __zoxide_z() {
      if [[ "$#" -eq 0 ]]; then
        builtin cd ~
      elif [[ "$#" -eq 1 ]] && { [[ -d "$1" ]] || [[ "$1" = '-' ]] || [[ "$1" =~ ^[-+][0-9]$ ]]; }; then
        builtin cd "$1"
      else
        local result
        result="$(command zoxide query --exclude "$(pwd)" -- "$@")" && builtin cd "${result}"
      fi
    }
  fi
fi
eval "$(starship init zsh)"
source <(carapace chmod zsh)

# cfi is find all ignoring .git
alias cfi='cd $(find . -type d -path "./.git" -prune -o -type d -not -path "*/\.*" -print | fzf --reverse --preview "ls --color {}")'
# cf is find all
alias cf='cd $(fd --type d --hidden --exclude .git | fzf --reverse --preview "ls --color {}")'
alias git-reset='git checkout main && git pull'

# nvimfi is find all files ignoring .git
alias nvimfi='nvim "$(find . -type f -path "./.git" -prune -o -type f -not -path "*/\.*" -print | fzf --preview "bat --color=always {}")"'

alias latest='git add . && git commit -m "latest" && git push'
alias nxi='nix'
alias wtr='git worktree remove'
alias wtl='git worktree list'
alias wta='git worktree add'
alias wt='git worktree'
alias wtd='git worktree remove'
alias k='kubectl'
alias nix-env='echo "panic: nix-env is disabled (#61)" >&2 && false'
alias vim='nvim'
alias os='spectr'
alias osv='spectr validate --all --strict'


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
zi load zpm-zsh/clipboard

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Noncase-sensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "\$\{(s.:.)LS_COLORS\}"
zstyle ':completion:*' menu no

# bun completions
[ -s "/home/connerohnesorge/.bun/_bun" ] && source "/home/connerohnesorge/.bun/_bun"

# Key bindings for word-by-word navigation for auto-completion
bindkey '^[[1;5C' forward-word      # Ctrl+Right - move forward one word
bindkey '^[[1;5D' backward-word     # Ctrl+Left - move backward one word

if [[ "$OSTYPE" == "darwin"* ]]; then
    export PATH="/Users/connerohnesorge/.config/herd-lite/bin:$PATH"
    export PHP_INI_SCAN_DIR="/Users/connerohnesorge/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
fi
source <(kubectl completion zsh)


# Turso
export PATH="$PATH:/home/connerohnesorge/.turso"

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# opencode
export PATH=/home/connerohnesorge/.opencode/bin:$PATH


# Added by CodeRabbit CLI installer
export PATH="$HOME/.local/bin:$PATH"
