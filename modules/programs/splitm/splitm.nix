/**
# Custom Program: splitm - File Section Splitter

## Description
Command-line utility for splitting files into multiple sections based on a delimiter.
Useful for extracting sections from documents, breaking up large files, or processing
structured text data with clear separators.

## Platform Support
- ✅ NixOS
- ✅ Darwin (macOS)
- ✅ Cross-platform Python implementation

## What This Provides
- **File Splitting**: Split input file by custom delimiter (default: "---")
- **Flexible Output**: Configurable output filename prefix
- **Text Processing**: UTF-8 encoding support for international text
- **CLI Interface**: Standard command-line argument parsing

## Usage
```bash
# Split file using default delimiter (---)
splitm input.txt

# Custom delimiter and output prefix
splitm -d "===" -p "part_" document.txt

# Help information
splitm --help
```

## Implementation
- Written in Python 3 with robust error handling
- Uses argparse for CLI argument processing
- Configured with flake8 ignores for line length and style preferences
- Self-contained with no external dependencies
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
  program =
    pkgs.writers.writePython3Bin "splitm" {
      flakeIgnore = [
        "E501"
        "W503"
        "W391"
      ];
    } ''
      ${builtins.readFile ./splitm.py}
    '';
in
  delib.module {
    name = "programs.splitm";

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
