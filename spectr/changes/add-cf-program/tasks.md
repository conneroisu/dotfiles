# Implementation Tasks

## 1. Create Program Module
- [ ] 1.1 Create `modules/programs/cf/` directory
- [ ] 1.2 Write `modules/programs/cf/cf.sh` shell script with fd + fzf logic
- [ ] 1.3 Create `modules/programs/cf/default.nix` with Denix module pattern
- [ ] 1.4 Add proper dependency wrapping (fd, fzf, coreutils)
- [ ] 1.5 Include nixos and darwin platform support sections

## 2. Remove Legacy Alias
- [ ] 2.1 Remove line 50 from `.zshrc` (`alias cf='cd $(fd ...'`)
- [ ] 2.2 Verify no other references to `cf` alias exist in dotfiles

## 3. Testing
- [ ] 3.1 Build the program module: `cd modules/programs/cf && nix build`
- [ ] 3.2 Test on NixOS: `nixos-rebuild build --flake .`
- [ ] 3.3 Run `cf` manually in a test directory to verify functionality
- [ ] 3.4 Test cancellation behavior (ESC/Ctrl-C)
- [ ] 3.5 Verify engineer feature automatically includes cf

## 4. Integration
- [ ] 4.1 Run `nix develop -c lint` to check for linting issues
- [ ] 4.2 Run `nix fmt` to format all Nix code
- [ ] 4.3 Verify `nix flake check` passes
