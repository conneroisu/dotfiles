/**
# Program Module: catls (Enhanced File Browser)

## Description
A Go-based enhanced file listing utility that provides XML-formatted
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
- **Language**: Go 1.24+
- **Framework**: Cobra CLI
- **Source**: ./main.go, ./cmd/root.go
- **Dependencies**: github.com/spf13/cobra
- **Build**: pkgs.buildGoModule

## Usage
```bash
catls                         # List current directory
catls /path/to/dir           # List specific directory
catls -r                     # Recursive listing
catls --globs "*.py"         # Include only Python files
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
  program = pkgs.buildGoModule {
    pname = "catls";
    version = "2.0.0";

    src = ./.;

    vendorHash = "sha256-m5mBubfbXXqXKsygF5j7cHEY+bXhAMcXUts5KBKoLzM=";

    meta = with pkgs.lib; {
      description = "Enhanced file listing utility with XML, Markdown, and JSON output";
      homepage = "https://github.com/connerosiu/dotfiles";
      license = licenses.mit;
      maintainers = [];
    };
  };
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
