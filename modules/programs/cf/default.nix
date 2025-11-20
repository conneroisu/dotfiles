/**
# Program Module: cf (Change Directory Fuzzy)

## Description
A fuzzy directory finder that combines fd and fzf for interactive directory
navigation. Outputs the selected directory path for use with cd.

## Platform Support
- ✅ NixOS
- ✅ Darwin

## Features
- Fuzzy search through directory tree
- Preview directories with ls
- Hidden directory support (excludes .git)
- Graceful cancellation (ESC/Ctrl-C)
- Optional starting directory argument

## Implementation
- **Language**: Bash
- **Source**: ./cf.sh
- **Build**: writeShellApplication
- **Dependencies**: fd, fzf, coreutils

## Usage
```bash
cd $(cf)           # Search from current directory
cd $(cf ~/code)    # Search from specific directory
```

## Common Use Cases
- Quick navigation to deeply nested directories
- Exploring unfamiliar codebases
- Switching between project directories
- Finding directories without remembering exact paths

## Configuration
Enabled via:
- `myconfig.programs.cf.enable = true`
- Or automatically with engineer feature
*/
{
  pkgs,
  lib,
  delib,
  ...
}: let
  inherit (delib) singleEnableOption;

  program = pkgs.writeShellApplication {
    name = "cf";
    text = builtins.readFile ./cf.sh;
    runtimeInputs = with pkgs; [
      fd
      fzf
      coreutils
    ];
  };
in
  delib.module {
    name = "programs.cf";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [program];
    };

    darwin.ifEnabled = {
      environment.systemPackages = [program];
    };
  }
