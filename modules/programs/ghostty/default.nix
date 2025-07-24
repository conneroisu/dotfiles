/**
# Program Module: Ghostty Terminal Emulator

## Description
Configuration module for Ghostty, a modern GPU-accelerated terminal emulator
that provides fast rendering, comprehensive Unicode support, and seamless
integration with terminal workflows. Supports platform-specific configuration
for Linux and macOS environments.

## Platform Support
- ✅ NixOS (Linux)
- ✅ Darwin (macOS)

## Features
- **GPU Acceleration**: Hardware-accelerated text rendering
- **Unicode Support**: Full Unicode and emoji support
- **Shell Integration**: Deep shell integration with zsh
- **Platform Optimization**: Different settings for Linux and macOS
- **Modern Terminal Features**: True color, ligatures, and more

## Configuration Differences
### Linux
- Window decorations disabled for better tiling window manager integration
- Optimized for desktop Linux environments

### macOS
- Window decorations enabled (native macOS window chrome)
- Integrated with macOS system conventions

## Common Settings
- **Font**: CodeNewRoman Nerd Font for programming
- **Shell**: zsh with full integration
- **Theme**: Dark background (#000000)
- **Key Bindings**: shift+enter for newline insertion
- **Working Directory**: Inherits from parent process

## Integration Points
- Works with Hyprland tiling window manager (Linux)
- Integrates with macOS window management
- Compatible with zsh configurations
- Supports development workflows

## Usage
Enabled automatically when Hyprland feature is active, or can be enabled
individually via:
```nix
myconfig.programs.ghostty.enable = true;
```

## Implementation
Uses Home Manager to deploy platform-specific configuration files:
- Linux: Uses ghostty.linux config (no window decorations)
- macOS: Uses ghostty.macos config (with window decorations)
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
  inherit (pkgs.stdenv) isDarwin isLinux;
in
  delib.module {
    name = "programs.ghostty";

    options = singleEnableOption false;

    home.ifEnabled = {
      # Enable Ghostty terminal emulator program
      programs.ghostty = {
        enable = true;
        package = pkgs.ghostty or null;
      };

      # Deploy platform-specific configuration file
      xdg.configFile."ghostty/config" = {
        source =
          if isLinux
          then ../../../.config/ghostty/ghostty.linux
          else if isDarwin
          then ../../../.config/ghostty/ghostty.macos
          else throw "Unsupported platform for Ghostty configuration";
      };
    };
  }
