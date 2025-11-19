# Change: Add cf program for fuzzy directory navigation

## Why
The current `cf` alias in .zshrc relies on external tools (`fd` and `fzf`) being available and configured correctly. By converting it to a standalone program module, we gain:
- Consistent deployment across all systems via Nix
- Proper dependency management
- Cross-platform support (NixOS/Darwin)
- Integration with the engineer feature for automatic availability

## What Changes
- Create new `cf` program module in `modules/programs/cf/`
- Implement shell script wrapper around fd + fzf for directory navigation
- Remove hard-coded alias from `.zshrc`
- Add to engineer feature's default program set

## Impact
- Affected specs: `shell-utilities` (new capability)
- Affected code:
  - New: `modules/programs/cf/default.nix` (Nix module definition)
  - New: `modules/programs/cf/cf.sh` (shell script implementation)
  - Modified: `.zshrc` (remove line 50: `alias cf=...`)
  - Modified: `modules/features/engineer.nix` (implicit - cf available to engineer users)
