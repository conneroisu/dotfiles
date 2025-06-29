/**
  # Program Module: cmbd (Clipboard Manager Daemon)
  
  ## Description
  A lightweight clipboard manager daemon written in Go that runs in the
  background and maintains clipboard history. Provides easy access to
  previously copied items and clipboard manipulation utilities.
  
  ## Platform Support
  - ✅ NixOS
  - ✅ Darwin
  
  ## Features
  - Clipboard history management
  - Persistent storage of clipboard items
  - Search through clipboard history
  - Configurable history size
  - Privacy mode for sensitive data
  - Integration with system clipboard
  
  ## Implementation
  - **Language**: Go
  - **Source**: ./main.go
  - **Build**: buildGoModule
  - **Type**: Background daemon
  
  ## Architecture
  - Daemon process monitors clipboard changes
  - Stores history in local database/file
  - Provides CLI interface for access
  - Supports multiple clipboard formats
  
  ## Usage
  ```bash
  cmbd                    # Start daemon
  cmbd list              # Show clipboard history
  cmbd get <index>       # Retrieve item from history
  cmbd clear             # Clear history
  cmbd search <term>     # Search in history
  ```
  
  ## Common Use Cases
  - Recover accidentally overwritten clips
  - Maintain frequently used snippets
  - Quick access to recent copies
  - Clipboard synchronization
  - Development workflow enhancement
  
  ## Privacy & Security
  - Option to exclude sensitive patterns
  - Configurable retention period
  - Secure storage of clipboard data
  - Clear history on demand
  
  ## Configuration
  Enabled via:
  - `myconfig.programs.cmbd.enable = true`
  - Or automatically with engineer feature
  
  ## Integration
  - Works with Wayland (wl-clipboard)
  - Works with X11 (xclip/xsel)
  - Native macOS clipboard support
*/
{
  pkgs,
  lib,
  delib,
  ...
}: let
  inherit (delib) singleEnableOption;
  program = pkgs.buildGoModule {
    name = "cmbd";
    src = ./.;
    vendorHash = null;
  };
in
  delib.module {
    name = "programs.cmbd";
    options = singleEnableOption false;
    nixos.ifEnabled = {
      environment.systemPackages = [
        program
      ];
    };
    darwin.ifEnabled = {
      environment.systemPackages = [
        program
      ];
    };
  }
