/**
  # Program Module: catls (Enhanced File Browser)
  
  ## Description
  A Python-based enhanced file listing utility that provides XML-formatted
  output of directory contents with file filtering and pattern matching.
  Useful for code analysis and file content inspection.
  
  ## Platform Support
  - ✅ NixOS
  - ✅ Darwin
  
  ## Features
  - XML-formatted output
  - Pattern matching for file inclusion/exclusion
  - Content filtering with glob patterns
  - Binary file detection
  - File type detection
  - Recursive directory traversal
  - Line number display
  - Debug mode
  
  ## Implementation
  - **Language**: Python 3.11+
  - **Source**: ./catls.py
  - **Dependencies**: Python standard library
  - **Build**: Nix writers.writePython3Bin
  
  ## Usage
  ```bash
  catls                         # List current directory
  catls /path/to/dir           # List specific directory
  catls -r                     # Recursive listing
  catls --regex "*.py"         # Include only Python files
  catls --pattern "*import*"   # Show only lines with imports
  catls -n                     # Show line numbers
  ```
  
  ## Common Use Cases
  - Code analysis and inspection
  - File content search and filtering
  - Documentation generation
  - Codebase exploration
  
  ## Configuration
  Enabled via:
  - `myconfig.programs.catls.enable = true`
  - Or automatically with engineer feature
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
  program =
    pkgs.writers.writePython3Bin "catls" {
      libraries = [
      ];
    } ''
      ${builtins.readFile ./catls.py}
    '';
in
  delib.module {
    name = "programs.catls";

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
