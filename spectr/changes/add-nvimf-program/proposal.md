# Change: Add nvimf program for fuzzy file opening

## Why
The current `nvimf` alias in .zshrc relies on external tools (fzf, bat, nvim) being available and configured correctly. By converting it to a standalone program module, we gain:
- Consistent deployment across all systems via Nix
- Proper dependency management
- Cross-platform support (NixOS/Darwin)
- Integration with the engineer feature for automatic availability
- Elimination of shell-specific configuration scattered across rc files

## What Changes
- Create new `nvimf` program module in `modules/programs/nvimf/`
- Implement shell script wrapper around fzf + bat + nvim for interactive file opening
- Remove hard-coded alias from `.zshrc` (line 53)
- Add to engineer feature's default program set

## Impact
- Affected specs: `shell-utilities` (adding new file selection capability)
- Affected code:
  - New: `modules/programs/nvimf/default.nix` (Nix module definition)
  - New: `modules/programs/nvimf/nvimf.sh` (shell script implementation)
  - Modified: `.zshrc` (remove line 53: `alias nvimf='nvim "$(fzf --preview "bat --color=always {}")"'`)
  - Modified: `modules/features/engineer.nix` (implicit - nvimf available to engineer users)
