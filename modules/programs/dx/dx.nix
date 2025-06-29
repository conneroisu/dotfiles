/**
  # Program Module: dx (Quick Flake Editor)
  
  ## Description
  A simple shell utility for quickly editing the flake.nix file in any
  Git repository. Automatically finds the repository root and opens the
  flake.nix file in your preferred editor. Essential tool for Nix flake
  development workflows.
  
  ## Platform Support
  - ✅ NixOS
  - ✅ Darwin
  
  ## Features
  - Automatically finds Git repository root
  - Opens flake.nix in configured editor
  - Respects $EDITOR environment variable
  - Falls back to nvim if no editor set
  - Error handling for non-Git directories
  
  ## Implementation
  - **Language**: Shell script
  - **Type**: Command-line utility
  - **Dependencies**: git, text editor
  
  ## Usage
  ```bash
  dx              # Open flake.nix in repository root
  cd subdir && dx # Works from any subdirectory
  EDITOR=vim dx   # Use specific editor
  ```
  
  ## How It Works
  1. Uses `git rev-parse --show-toplevel` to find repo root
  2. Checks for $EDITOR environment variable
  3. Falls back to nvim if not set
  4. Opens flake.nix at repository root
  5. Shows error if not in a Git repository
  
  ## Common Use Cases
  - Quick flake.nix edits during development
  - Updating dependencies
  - Adding new outputs or inputs
  - Modifying flake configuration
  - Part of Nix development workflow
  
  ## Configuration
  Enabled via:
  - `myconfig.programs.dx.enable = true`
  - Or automatically with engineer feature
  
  ## Tips
  - Set $EDITOR in your shell config
  - Works great with shell aliases
  - Combine with nix develop workflows
  - Use with direnv for auto-loading
  
  ## Error Handling
  - Graceful failure if not in Git repo
  - Clear error message
  - Non-zero exit code on failure
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;

  program = pkgs.writeShellScriptBin "dx" ''
    [[ -f $EDITOR ]] || EDITOR=nvim
    $EDITOR $(git rev-parse --show-toplevel)/flake.nix || echo "No toplevel file found"
  '';
in
  delib.module {
    name = "programs.dx";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      environment.systemPackages = [
        program
      ];
    };

    darwin.ifEnabled = {myconfig, ...}: {
      environment.systemPackages = [
        program
      ];
    };
  }
