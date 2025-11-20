# Implementation Tasks

## 1. Create Program Module
- [x] 1.1 Create `modules/programs/nvimf/` directory
- [x] 1.2 Write `modules/programs/nvimf/nvimf.sh` shell script with fzf + bat + nvim logic
- [x] 1.3 Create `modules/programs/nvimf/default.nix` with Denix module pattern
- [x] 1.4 Add proper dependency wrapping (fzf, bat, neovim)
- [x] 1.5 Include nixos and darwin platform support sections
- [x] 1.6 Configure fzf with appropriate preview command and options

## 2. Remove Legacy Alias
- [x] 2.1 Remove line 53 from `.zshrc` (`alias nvimf='nvim "$(fzf --preview "bat --color=always {}")"'`)
- [x] 2.2 Verify no other references to `nvimf` alias exist in dotfiles (check nushell config.nu)

## 3. Testing
- [x] 3.1 Build the program module: `cd modules/programs/nvimf && nix build`
- [x] 3.2 Test on NixOS: `nixos-rebuild build --flake .`
- [x] 3.3 Run `nvimf` manually in a test directory to verify functionality
- [x] 3.4 Test file selection and verify Neovim opens correctly
- [x] 3.5 Test cancellation behavior (ESC/Ctrl-C)
- [x] 3.6 Test preview functionality with various file types
- [x] 3.7 Verify engineer feature automatically includes nvimf

## 4. Integration
- [x] 4.1 Run `nix develop -c lint` to check for linting issues
- [x] 4.2 Run `nix fmt` to format all Nix code
- [x] 4.3 Verify `nix flake check` passes
