# Dotfiles - Conner Ohnesorge
[![.github/workflows/ci.yml](https://github.com/conneroisu/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/conneroisu/dotfiles/actions/workflows/ci.yml)

## Introduction

![Pasted image 20250224165002.png](assets/Pasted%20image%2020250224165002.png)

A NixOS/Home Manager dotfiles repository using the **Denix** framework for modular configuration management. This repository provides unified configuration across multiple platforms (NixOS, macOS via nix-darwin, Home Manager) with type-safe, composable modules and automatic discovery.

### Key Features

- **Modular Architecture**: Feature-based configuration system with automatic dependency resolution
- **Multi-Platform Support**: Unified configuration for NixOS, macOS (Darwin), and standalone Home Manager
- **Type Safety**: Leverages Nix's type system through proper option definitions
- **Theme System**: Stylix integration with Base16 color schemes for consistent theming
- **Custom Programs**: Self-contained applications with cross-platform deployment
- **Development Templates**: Ready-to-use flake templates for various programming languages

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

## Architecture

This repository uses the **Denix framework** for modular configuration management, providing type-safe, composable modules with automatic discovery and loading.

### Module System

**Configuration Modules** (`modules/config/`):
- `constants.nix` - Read-only user constants (username, email, etc.)
- `user.nix` - User account configuration for NixOS and Darwin
- `hosts.nix` - Host type definitions and feature mapping system
- `args.nix` - Shared arguments between nixos and home-manager configurations
- `home.nix` - Home Manager configuration patterns
- `rices.nix` - Theme system configuration

**Feature Modules** (`modules/features/`):
- System-level capabilities that can be enabled per-host
- Platform-specific sections: `nixos.ifEnabled`, `darwin.ifEnabled`, `home.ifEnabled`
- Examples: `engineer.nix`, `hyprland.nix`, `nvidia.nix`, `audio.nix`, `bluetooth.nix`

**Custom Program Modules** (`modules/programs/`):
- Self-contained applications with source code and build expressions
- Cross-platform deployment support (nixos/darwin)
- Examples: `catls/` (Ruby), `cmbd/` (Go), `convert_img/` (Python), `dx/` (shell script)

### Host Configuration

Hosts are configured using the `delib.host` pattern with:
- Type classification (desktop/laptop/server)
- Feature enablement through `myconfig.features.*`
- Platform-specific configuration sections

### Development Commands

All commands should be run using `nix develop -c <command>` to ensure proper shell environment:

```bash
# Linting and validation
nix develop -c lint              # Run linting tools (statix, deadnix, nix flake check)
nix fmt                          # Format code using treefmt

# Development
nix develop -c dx                # Edit the flake.nix file

# Testing
cd modules/programs/<program> && nix build  # Test custom program builds
cd modules/programs/convert_img && python -m pytest tests/  # Run Python tests

# Debugging
nix flake check                  # Validate flake outputs
nixos-rebuild build --flake . --show-trace  # Build without switching (NixOS)
```

## Development Templates

This repository provides ready-to-use flake templates for various programming languages and frameworks. These templates create isolated development environments without affecting your system configuration.

### Available Templates

```bash
# General development shell
nix flake init -t github:conneroisu/dotfiles#devshell

# Language-specific templates
nix flake init -t github:conneroisu/dotfiles#rust-shell      # Rust development
nix flake init -t github:conneroisu/dotfiles#go-shell        # Go development  
nix flake init -t github:conneroisu/dotfiles#go-templ-shell  # Go + Templ
nix flake init -t github:conneroisu/dotfiles#remix-js-shell  # Remix.js development
nix flake init -t github:conneroisu/dotfiles#laravel-shell   # Laravel development
nix flake init -t github:conneroisu/dotfiles#phoenix-shell   # Elixir Phoenix development
```

### Template Features

- **Isolated Environments**: Each template provides development dependencies without global installation
- **Complete Toolchains**: Includes language servers, formatters, and build tools
- **Consistent Configuration**: Standardized development environment across projects
- **Easy Extension**: Templates can be customized for project-specific needs

### Extending Templates

Templates can be extended with package builds. Example for Go projects:

```nix
{
  inputs.dotfiles.url = "github:conneroisu/dotfiles";
  outputs = {
    self,
    nixpkgs,
    dotfiles,
  }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    packages.x86_64-linux.default = pkgs.buildGoModule {
      pname = "my-go-project";
      version = "0.0.1";
      src = ./.;
      vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      doCheck = false;
      meta = with pkgs.lib; {
        description = "My Go project";
        homepage = "https://github.com/my-go-project";
        license = licenses.mit;
        maintainers = with maintainers; [conneroisu];
      };
    };
  };
}
```
