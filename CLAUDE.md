# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a NixOS/Home Manager dotfiles repository using the **Denix** framework for modular configuration management. It supports multiple platforms (NixOS, macOS via nix-darwin, Home Manager) with unified configuration.

## Common Tools

Use the nixos and context7 mcp for background info (both of these should be used atleast 3 times anytime you edit a nix file)

### Development Commands
All commands should be run using `nix develop -c <command>` to ensure the proper shell environment is loaded.
- `nix develop -c lint` - Run linting tools (statix, deadnix, nix flake check) (if on nixos, should run `nixos-rebuild build --flake .` for better results)
- `nix develop -c dx` - Edit the flake.nix file
- `nix fmt` - Format code using treefmt

#### Testing
- Individual program tests: `cd modules/programs/<program-name> && nix build` to test custom program builds
- convert_img tests: `cd modules/programs/convert_img && python -m pytest tests/`
- if you edit any program in `modules/programs/`, you should run the edited program manually to ensure it works in addition to the tests.

#### Installation/Rebuild

```bash
# macOS
darwin-rebuild switch --flake . --show-trace

# Linux (Home Manager only)
nix build .#homeConfigurations.x86_64-linux.activationPackage

# NixOS
nixos-rebuild build --flake .
```

### Templates

Create development shells with:
```bash
nix flake init -t github:conneroisu/dotfiles#<template-name>
```
Available templates: devshell, rust-shell, go-shell, go-templ-shell, remix-js-shell, laravel-shell, phoenix-shell

### Debugging and Troubleshooting

- `nix flake check` - Validate flake outputs and check for errors
- `nix eval .#nixosConfigurations.<hostname>.config.system.build.toplevel` - Check NixOS configuration evaluation
- `nix show-derivation` - Inspect derivation details for debugging builds
- `nixos-rebuild build --flake . --show-trace` - Build without switching to catch configuration errors

## Architecture

### Module System Overview

The repository uses the **Denix framework** for modular configuration management, providing type-safe, composable modules with automatic discovery and loading.

### Module Types and Structure

**Configuration Modules** (`modules/config/`):
- `constants.nix` - Read-only user constants (username, email, etc.)
- `user.nix` - User account configuration for NixOS and Darwin
- `hosts.nix` - Host type definitions and feature mapping system
- `args.nix` - Shared arguments between nixos and home-manager configurations
- `home.nix` - Home Manager configuration patterns
- `rices.nix` - Theme system configuration

**Feature Modules** (`modules/features/`):
- System-level capabilities that can be enabled per-host
- Use `delib.module` with `singleEnableOption false` pattern
- Platform-specific sections: `nixos.ifEnabled`, `darwin.ifEnabled`, `home.ifEnabled`
- Examples: `engineer.nix`, `hyprland.nix`, `nvidia.nix`, `audio.nix`, `bluetooth.nix`

**Custom Program Modules** (`modules/programs/`):
- Self-contained applications with source code and build expressions
- Cross-platform deployment support (nixos/darwin)
- Examples: `catls/` (Ruby), `cmbd/` (Go), `convert_img/` (Python), `dx/` (shell script)

**Host Configurations** (`hosts/`):
- Use `delib.host` with type classification (desktop/laptop/server)
- Feature enablement through `myconfig.features.*`
- Platform-specific configuration sections

**Theme Configurations** (`rices/`):
- Use `delib.rice` with Stylix integration
- Consistent theming across applications using Base16 color schemes

### Denix Framework Patterns

**Module Creation**:
```nix
delib.module {
  name = "feature-name";
  options.myconfig.features.featureName = singleEnableOption false;
  nixos.ifEnabled = { /* NixOS config */ };
  darwin.ifEnabled = { /* macOS config */ };
  home.ifEnabled = { /* Home Manager config */ };
}
```

**Host Configuration**:
```nix
delib.host {
  type = "desktop"; # or "laptop", "server"
  features = { featureName = true; };
  rice = "dark";
  nixos = { /* NixOS-specific config */ };
  darwin = { /* Darwin-specific config */ };
}
```

**Custom Program Packaging**:
```nix
delib.module {
  name = "program-name";
  nixos.ifEnabled.environment.systemPackages = [ pkgs.program-name ];
  darwin.ifEnabled.environment.systemPackages = [ pkgs.program-name ];
}
```

### Module Discovery and Loading

The `flake.nix` uses Denix's auto-discovery system:
```nix
denix.lib.configurations {
  homeManagerUser = "connerohnesorge";
  paths = [./hosts ./modules ./rices]; # Auto-discovery paths
}
```

This automatically creates:
- `nixosConfigurations`
- `homeConfigurations` 
- `darwinConfigurations`

### Feature Dependencies

Features automatically enable required programs:
- `engineer.enable = true` → enables development tools (`dx`, `convert_img`, etc.)
- `hyprland.enable = true` → enables Wayland desktop with supporting tools
- Dependencies resolved through the Denix module system

### Multi-Platform Support

**Conditional Configuration**: Separate platform sections in modules
**Shared Configuration**: Maximize reuse between platforms where possible
**Platform Detection**: Automatic handling of nixos vs darwin differences

### Important Files
- `flake.nix` - Main entry point with system configurations
- `modules/config/constants.nix` - User constants (username, email, etc.)
- `modules/config/hosts.nix` - Host type definitions and feature mappings
- `shell.nix` - Development environment with custom scripts

## Development Notes

### Working with Modules

**Creating New Feature Modules**:
1. Create a new `.nix` file in `modules/features/`
2. Use the `delib.module` pattern with `singleEnableOption false`
3. Define platform-specific configuration in `nixos.ifEnabled`, `darwin.ifEnabled`, `home.ifEnabled` sections
4. Features are automatically discovered and can be enabled in host configurations

**Creating Custom Program Modules**:
1. Create a directory in `modules/programs/` with source code and `default.nix`
2. Define the package derivation with cross-platform support
3. Export the module using `delib.module` pattern
4. Programs are automatically available after rebuild

**Modifying Host Configurations**:
- Edit files in `hosts/` to enable/disable features
- Use `myconfig.features.featureName = true` to enable features
- Platform-specific settings go in `nixos` or `darwin` sections

### Best Practices

- **Module Isolation**: Each module should be self-contained with minimal external dependencies
- **Platform Awareness**: Always consider both nixos and darwin when creating modules
- **Feature Dependencies**: Let the Denix system handle automatic dependency resolution
- **Theme Integration**: Use Stylix-compatible configuration for consistent theming
- **Type Safety**: Leverage Nix's type system through proper option definitions

### Templates and Development

Templates provide isolated development environments for different languages/frameworks:
- Each template is a complete flake.nix with development dependencies
- Use for project-specific development without affecting system configuration
- Available for: Go, Rust, Elixir/Phoenix, Laravel, Remix.js, Lua, and general devshell
