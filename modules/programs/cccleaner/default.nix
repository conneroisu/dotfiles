/**
# Program Module: cccleaner (Claude Code History Cleaner)

## Description
A streamlined Python tool for cleaning Claude Code history entries from .claude.json files.
Removes short messages without pasted content to reduce clutter in conversation logs.

## Platform Support
- ✅ NixOS
- ✅ Darwin

## Features
- Configurable message length filtering
- Automatic backup creation
- Dry-run preview mode
- Per-project statistics
- Safe JSON handling

## Usage
```bash
cccleaner                    # Clean ~/.claude.json (with backup)
cccleaner --dry-run          # Preview what would be cleaned
cccleaner -d                 # Same as --dry-run (short form)
cccleaner --min-length 5     # Remove messages < 5 characters
cccleaner --no-backup        # Clean without creating backup
```

## Configuration
Enabled via:
- `myconfig.programs.cccleaner.enable = true`
- Or automatically with engineer feature
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
  program =
    pkgs.writers.writePython3Bin "cccleaner" {
      libraries = [];
      flakeIgnore = [
        "E501"  # line too long
        "W503"  # line break before binary operator
        "E203"  # whitespace before ':'
      ];
    } ''
      ${builtins.readFile ./cccleaner.py}
    '';
in
  delib.module {
    name = "programs.cccleaner";

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