# remove-comments

A multi-language comment removal tool that intelligently removes comments from source code files while preserving string literals, docstrings, and code structure.

## Features

- **Multi-language support**: Python, JavaScript, TypeScript, Go, Rust, Java, Ruby, C/C++, Shell, Nix
- **Intelligent parsing**: Distinguishes between comments and string literals
- **Docstring preservation**: Keeps Python docstrings intact
- **Structure preservation**: Maintains indentation and whitespace
- **Flexible output**: Write to stdout, file, or modify in-place

## Installation

This program is automatically available when enabled in your NixOS/Home Manager configuration:

```nix
myconfig.programs.remove-comments.enable = true;
```

Or it's automatically included with the `engineer` feature.

## Usage

### Basic usage

```bash
# Print cleaned code to stdout
remove-comments input.py

# Redirect to a new file
remove-comments input.py > output.py

# Write to a specific output file
remove-comments input.py -o output.py

# Modify file in place
remove-comments input.py --in-place

# Verbose mode
remove-comments input.py -v
```

### Supported Languages

| Language          | Extensions            | Single-line | Multi-line   | Special handling |
|-------------------|-----------------------|-------------|--------------|------------------|
| Python            | `.py`                 | `#`         | `"""`/`'''`  | Preserves docstrings |
| JavaScript        | `.js`, `.jsx`         | `//`        | `/* */`      | - |
| TypeScript        | `.ts`, `.tsx`         | `//`        | `/* */`      | - |
| Go                | `.go`                 | `//`        | `/* */`      | - |
| Rust              | `.rs`                 | `//`        | `/* */`      | - |
| Java              | `.java`               | `//`        | `/* */`      | - |
| Ruby              | `.rb`                 | `#`         | `=begin/=end`| - |
| C/C++             | `.c`, `.cpp`, `.h`, `.hpp` | `//`   | `/* */`      | - |
| Shell             | `.sh`, `.bash`        | `#`         | -            | - |
| Nix               | `.nix`                | `#`         | `/* */`      | - |

## Examples

### Python

**Input:**
```python
def calculate(n):
    """This docstring is preserved."""
    # This comment is removed
    return n * 2  # Inline comment removed
```

**Output:**
```python
def calculate(n):
    """This docstring is preserved."""

    return n * 2
```

### JavaScript

**Input:**
```javascript
// This comment is removed
const url = "https://example.com"; // Comment removed
/* Multi-line comment
   also removed */
const msg = "// This is preserved";
```

**Output:**
```javascript

const url = "https://example.com";


const msg = "// This is preserved";
```

## How It Works

1. **File type detection**: Determines comment syntax from file extension
2. **State machine parsing**: Character-by-character parsing with state tracking
3. **String detection**: Identifies and preserves string literals (handles escapes)
4. **Docstring detection**: Special handling for Python docstrings
5. **Comment removal**: Strips comments while maintaining structure

## Testing

Run the test suite:

```bash
cd modules/programs/remove-comments
python -m pytest tests/
```

Or run tests directly:

```bash
python tests/test_remove_comments.py
```

## Limitations

- Does not handle all edge cases of every language's syntax
- Raw strings and template literals may have edge cases
- Very complex string escaping might not be handled perfectly
- Does not preserve comments in languages with non-standard syntax

## Development

The program consists of:
- `remove_comments.py`: Main implementation
- `remove-comments.nix`: Nix package definition
- `tests/test_remove_comments.py`: Test suite
- `README.md`: This file

To modify the program:
1. Edit `remove_comments.py`
2. Run tests to ensure functionality
3. Rebuild your NixOS/Home Manager configuration

## License

Part of the dotfiles repository.
