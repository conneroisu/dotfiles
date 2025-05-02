# dotfiles - Conner Ohnesorge
[![.github/workflows/ci.yml](https://github.com/conneroisu/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/conneroisu/dotfiles/actions/workflows/ci.yml)

## Introduction

![Pasted image 20250224165002.png](assets/Pasted%20image%2020250224165002.png)

dotfiles for my personal setup

Uses [snowfall](https://github.com/snowfallorg/lib) for configuration management.

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

Listing all `.desktop` files:

```bash
 ls -l /run/current-system/sw/share/applications
```

Config MimeTypes:
```bash
# See settings
/etc/xdg/mimeapps.list
```
