# dotfiles - Conner Ohnesorge

## Introduction

dotfiles for my personal setup

## Installation

```bash
git clone --recurse-submodules -j8 https://github.com/conneroisu/dotfiles.git
cd dotfiles

# MACOS
darwin-rebuild switch --flake . --show-trace

# LINUX
nix build .#homeConfigurations.x86_64-linux.activationPackage

# NIXOS
sudo nixos-rebuild switch --flake .
```

## Development


### Host

4 hosts are defined in `./hosts/`.

- ./hosts/x86_64-linux/
- ./hosts/x86_64-darwin/
- ./hosts/aarch64-darwin/
- ./hosts/aarch64-linux/

The hosts' shared packages are defined in `./hosts/Shared/`.
