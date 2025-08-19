/**
# Feature Module: Modern Shell Environment (Zsh-focused)

## Description
Provides a comprehensive modern shell environment centered around Zsh with
enhanced CLI tools, productivity utilities, and developer-focused enhancements.
This module includes modern replacements for traditional Unix tools and
powerful shell integrations for improved workflow efficiency.

## Platform Support
- ✅ NixOS (full support)
- ✅ Darwin (full support)

## What This Enables
- **Modern CLI Tools**: Enhanced replacements for ls, cat, grep, find, etc.
- **Shell Enhancement**: Starship prompt, Zsh completions, history management
- **Navigation**: fzf fuzzy finder, zoxide smart cd, directory jumping
- **Development Tools**: direnv, git, version managers, text processing
- **Terminal Experience**: bat syntax highlighting, delta git diffs

## Key Tools Included
### Navigation & Search
- `fzf` - Fuzzy finder for files, history, processes
- `fd` - Fast, user-friendly alternative to find
- `ripgrep` - Ultra-fast text search tool
- `zoxide` - Smart cd command that learns your habits

### Text & File Processing
- `bat` - Cat with syntax highlighting and Git integration
- `eza` - Modern ls replacement with Git status
- `delta` - Syntax-highlighted git diff viewer
- `jq` - JSON processor
- `tealdeer` - Fast tldr implementation

### Shell & Environment
- `starship` - Cross-shell prompt with Git and context info
- `atuin` - Enhanced shell history with sync capability
- `carapace` - Multi-shell completion engine
- `zinit` - Zsh plugin manager

### Development Environment
- `direnv` - Environment switcher for projects
- `git` - Version control system
- `uv` - Fast Python package installer
- `stow` - Symlink farm manager

## Integration Notes
- Automatically enabled by `engineer.nix` feature
- Provides foundation tools used by other development features
- Cross-platform package list ensures consistency across NixOS and Darwin

## Performance Characteristics
- Minimal startup overhead with efficient tool selection
- Tools chosen for speed and modern UX improvements
- Smart caching and indexing where applicable (atuin, zoxide)

## Dependencies
This is a foundational module with minimal external dependencies,
designed to be enabled by higher-level feature modules like `engineer.nix`.
*/
{
  delib,
  pkgs,
  inputs,
  ...
}: let
  inherit (delib) singleEnableOption;

  systemPackages = with pkgs; [
    zinit
    starship
    direnv
    nix-direnv
    bat
    wget
    fd
    jq
    fzf
    zellij
    atuin
    zoxide
    eza
    delta
    unzip
    htop
    tealdeer
    ripgrep
    stow
    carapace
    uv
    git
    man
    cmake
    yq
    graphite-cli
    lsof
    gdu
    # Editor
    neovim
    tree-sitter
    sad
  ];
in
  delib.module {
    name = "features.zshell";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment = {
        inherit systemPackages;
      };
    };

    darwin.ifEnabled = {
      environment = {
        inherit systemPackages;
      };
    };
  }
