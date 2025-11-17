/**
# Program Module: remove-comments (Comment Removal Tool)

## Description
A Python-based utility for removing comments from source code files while
preserving string literals, docstrings, whitespace, and code structure.
Supports multiple programming languages with language-specific comment syntax.

## Platform Support
- ✅ NixOS
- ✅ Darwin

## Features
- Multi-language support (Python, JS/TS, Go, Rust, Java, Ruby, C/C++, Shell, Nix)
- Preserves string literals (single and double quoted)
- Preserves Python docstrings
- Maintains code structure and indentation
- Handles both single-line and multi-line comments
- In-place editing or output to file/stdout
- Robust string/comment detection to avoid false positives

## Supported Languages
- Python (.py) - Preserves docstrings
- JavaScript/TypeScript (.js, .ts, .jsx, .tsx)
- Go (.go)
- Rust (.rs)
- Java (.java)
- Ruby (.rb)
- C/C++ (.c, .cpp, .h, .hpp)
- Shell (.sh, .bash)
- Nix (.nix)

## Implementation
- **Language**: Python 3
- **Source**: ./remove_comments.py
- **Type**: Command-line utility
- **Dependencies**: Python 3 standard library

## Usage
```bash
remove-comments input.py                  # Print to stdout
remove-comments input.py > output.py      # Redirect to file
remove-comments input.py -o output.py     # Write to output file
remove-comments input.py --in-place       # Modify file in place
remove-comments input.js -v               # Verbose mode
```

## How It Works
1. Detects file type from extension
2. Loads language-specific comment syntax configuration
3. Parses file character-by-character with state machine
4. Distinguishes between comments and string literals
5. Preserves docstrings in Python files
6. Maintains whitespace and indentation structure
7. Outputs cleaned code

## Common Use Cases
- Preparing code for minification
- Removing debug comments before deployment
- Creating comment-free code samples
- Code size reduction
- Educational purposes (showing code without comments)
- Pre-processing for code analysis tools

## Configuration
Enabled via:
- `myconfig.programs.remove-comments.enable = true`
- Or automatically with engineer feature

## Implementation Details
- Uses character-by-character parsing for accuracy
- Handles escape sequences in strings
- Tracks state for multi-line comments
- Special handling for Python docstrings
- Preserves trailing whitespace structure

## Examples

### Python
Removes # comments and non-docstring multi-line comments
Preserves ''' and """ docstrings

### JavaScript/TypeScript
Removes // and /* */ comments
Handles template literals correctly

### Go/Rust/Java/C++
Removes // and /* */ comments
Preserves string literals

### Ruby
Removes # comments and =begin/=end blocks
Preserves string literals

## Error Handling
- Validates file existence
- Checks for supported file types
- Graceful error messages
- Non-zero exit codes on failure

## Testing
Comprehensive test suite in tests/ directory covering:
- All supported languages
- String literal preservation
- Docstring preservation
- Multi-line comment handling
- Edge cases and corner cases
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;

  program =
    pkgs.writers.writePython3Bin "remove-comments" {
      flakeIgnore = ["E501" "W503" "E226"];
    }
    ./remove_comments.py;
in
  delib.module {
    name = "programs.remove-comments";

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
