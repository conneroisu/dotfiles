# Implementation Tasks

## 1. Create Program Module
- [ ] 1.1 Create `modules/programs/nvimf/` directory
- [ ] 1.2 Write `modules/programs/nvimf/nvimf.sh` shell script with fzf + bat + nvim logic
- [ ] 1.3 Create `modules/programs/nvimf/default.nix` with Denix module pattern
- [ ] 1.4 Add proper dependency wrapping (fzf, bat, neovim)
- [ ] 1.5 Include nixos and darwin platform support sections
- [ ] 1.6 Configure fzf with appropriate preview command and options

## 2. Remove Legacy Alias
- [ ] 2.1 Remove line 53 from `.zshrc` (`alias nvimf='nvim "$(fzf --preview "bat --color=always {}")"'`)
- [ ] 2.2 Verify no other references to `nvimf` alias exist in dotfiles (check nushell config.nu)

## 3. Testing
- [ ] 3.1 Build the program module: `cd modules/programs/nvimf && nix build`
- [ ] 3.2 Test on NixOS: `nixos-rebuild build --flake .`
- [ ] 3.3 Run `nvimf` manually in a test directory to verify functionality
- [ ] 3.4 Test file selection and verify Neovim opens correctly
- [ ] 3.5 Test cancellation behavior (ESC/Ctrl-C)
- [ ] 3.6 Test preview functionality with various file types
- [ ] 3.7 Verify engineer feature automatically includes nvimf

## 4. Integration
- [ ] 4.1 Run `nix develop -c lint` to check for linting issues
- [ ] 4.2 Run `nix fmt` to format all Nix code
- [ ] 4.3 Verify `nix flake check` passes
