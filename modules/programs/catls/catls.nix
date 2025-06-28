/**
  # Program Module: catls (Enhanced File Browser)
  
  ## Description
  A Ruby-based enhanced file listing utility that provides colorized
  and formatted directory listings with additional metadata. Improves
  upon standard `ls` with better visual presentation and information.
  
  ## Platform Support
  - ✅ NixOS
  - ✅ Darwin
  
  ## Features
  - Colorized output based on file types
  - Enhanced file metadata display
  - Human-readable file sizes
  - Git integration (if applicable)
  - Recursive directory traversal
  - Custom formatting options
  
  ## Implementation
  - **Language**: Ruby
  - **Source**: ./catls.rb
  - **Dependencies**: Ruby standard library
  - **Build**: Nix writers.writeRubyBin
  
  ## Usage
  ```bash
  catls                 # List current directory
  catls /path/to/dir   # List specific directory
  catls -la            # Long format with all files
  ```
  
  ## Common Use Cases
  - Quick directory overview with colors
  - File browsing in terminal
  - Integration with shell aliases
  - Scripting and automation
  
  ## Advantages over ls
  - Better color coding
  - More intuitive output
  - Consistent cross-platform behavior
  - Extensible Ruby implementation
  
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
    pkgs.writers.writeRubyBin "catls" {
      libraries = [
      ];
    } ''
      ${builtins.readFile ./catls.rb}
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
