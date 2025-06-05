# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a sophisticated NixOS/Home Manager dotfiles repository using the **Denix** framework for modular configuration management. It supports multiple platforms (NixOS, macOS via nix-darwin, Home Manager) with unified configuration.

## Common Commands

All commands should be run using `nix develop -c <command>` to ensure the proper shell environment is loaded.

### Development
- `nix develop -c dx` - Edit the main flake.nix file
- `nix develop -c lint` - Run linting tools (statix, deadnix, nix flake check)

### Installation/Rebuild
```bash
# macOS
darwin-rebuild switch --flake . --show-trace

# Linux (Home Manager only)
nix build .#homeConfigurations.x86_64-linux.activationPackage

# NixOS
sudo nixos-rebuild switch --flake .
```

### Templates
Create development shells with:
```bash
nix flake init -t github:conneroisu/dotfiles#<template-name>
```
Available templates: devshell, rust-shell, go-shell, go-templ-shell, remix-js-shell, laravel-shell

## Architecture

### Module Structure
- `modules/config/` - Core configuration (user, hosts, rices/themes)
- `modules/features/` - System-level features (engineer, hyprland, nvidia, audio, etc.)
- `modules/programs/` - Custom programs with their own source code
- `hosts/` - Host-specific configurations
- `rices/` - Theme configurations using Stylix

### Key Patterns

**Host Configuration**: Uses `delib.host` with type (desktop/laptop/server), feature sets, and platform-specific settings.

**Feature System**: Modular components enabled per-host:
- `engineer.enable` - Complete development environment
- `hyprland.enable` - Wayland desktop with supporting tools
- `nvidia.enable` - GPU drivers and configuration

**Multi-Platform Support**: Conditional logic for Darwin vs Linux with shared configuration where possible.

**Custom Programs**: Self-contained modules in `modules/programs/` with source code, build expressions, and cross-platform support.

### Important Files
- `flake.nix` - Main entry point with system configurations
- `modules/config/constants.nix` - User constants (username, email, etc.)
- `modules/config/hosts.nix` - Host type definitions and feature mappings
- `shell.nix` - Development environment with custom scripts

## Development Notes

- Uses Denix framework patterns (`delib.module`, `delib.host`, `delib.rice`)
- Features automatically enable required programs through dependency management
- Stylix provides unified theming across applications
- Templates provide isolated development environments for different languages/frameworks