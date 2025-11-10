<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# AGENTS.md - Coding Agent Guidelines

## Project Structure

```
dotfiles/
├── flake.nix                    # Main flake configuration
├── hosts/                      # Host-specific configurations
│   ├── oxe-nixos/             # Desktop NixOS config
│   ├── xps-nixos/             # Laptop NixOS config
│   └── mac-nix/               # macOS Darwin config
├── modules/                    # Modular configuration system
│   ├── config/                # Core configuration modules
│   │   ├── constants.nix      # User constants (username, email)
│   │   ├── user.nix          # User account configuration
│   │   ├── hosts.nix         # Host type definitions
│   │   ├── args.nix          # Shared arguments
│   │   ├── home.nix          # Home Manager patterns
│   │   └── rices.nix         # Theme system config
│   ├── features/              # System-level capabilities
│   │   ├── engineer.nix      # Development environment
│   │   ├── hyprland.nix      # Wayland desktop
│   │   ├── nvidia.nix        # NVIDIA graphics
│   │   ├── audio.nix         # Audio system
│   │   ├── bluetooth.nix     # Bluetooth support
│   │   ├── amd.nix           # AMD graphics
│   │   ├── secrets.nix       # Secret management
│   │   ├── student.nix       # Student tools
│   │   ├── darknet.nix       # Privacy/security
│   │   └── power-efficient.nix # Power management
│   └── programs/              # Custom applications
│       ├── dx/               # Flake editor script
│       ├── catls/            # Ruby file lister
│       ├── cmbd/             # Go command builder
│       ├── convert_img/      # Python image converter
│       ├── splitm/           # Screen splitter
│       └── proton-x/         # Proton launcher
├── rices/                     # Theme configurations
│   └── dark/                 # Dark theme with Stylix
├── templates/                 # Development templates
│   ├── devshell/             # General development
│   ├── rust-shell/           # Rust projects
│   ├── go-shell/             # Go projects
│   ├── go-templ-shell/       # Go + Templ
│   ├── remix-js-shell/       # Remix.js projects
│   ├── laravel-shell/        # Laravel PHP
│   ├── lua-shell/            # Lua development
│   ├── zig-shell/            # Zig projects
│   ├── cuda-shell/           # CUDA development
│   ├── rust-web-shell/       # Rust web projects
│   └── bun-shell/            # Bun.js projects
└── pkgs/                     # Custom package definitions
```

## Build/Test Commands
- **Lint**: `nix develop -c lint` (runs statix, deadnix, nix flake check)
- **Format**: `nix fmt` (alejandra for Nix, rustfmt, black for Python)
- **Single Test**: `cd modules/programs/convert_img && python -m pytest tests/test_convert_img.py::TestClassName::test_method`
- **Build Module**: `cd modules/programs/<program-name> && nix build`
- **Rebuild System**: `darwin-rebuild switch --flake .` (macOS) or `sudo nixos-rebuild switch --flake .` (NixOS)
- **Template Usage**: `nix flake init -t github:conneroisu/dotfiles#<template-name>`

## Code Style Guidelines
- **Nix**: Use alejandra formatting, prefer `let...in` blocks, use `delib.module` pattern for modules
- **Python**: Black formatting, type hints required, docstrings for classes/functions, pytest for tests
- **Imports**: Group by stdlib, third-party, local; use explicit imports over wildcards
- **Naming**: snake_case for files/functions, PascalCase for classes, kebab-case for Nix attributes
- **Error Handling**: Use proper exception types, validate inputs early, provide meaningful error messages
- **Module Structure**: Features in `modules/features/`, programs in `modules/programs/`, configs in `modules/config/`

## Architecture Notes
- Uses Denix framework for modular configuration management
- Platform-specific sections: `nixos.ifEnabled`, `darwin.ifEnabled`, `home.ifEnabled`
- Auto-discovery from `./hosts ./modules ./rices` paths
- Feature dependencies resolved automatically through module system
- Multi-platform support: NixOS, macOS (nix-darwin), Home Manager
- Theme system integrated with Stylix for consistent styling
