/**
# Program Module: nviml (Neovim Live Search)

## Description
A sophisticated terminal-based live grep tool that provides real-time search
through codebases with enhanced preview functionality. Combines the speed of
ripgrep with the interactivity of fzf and the syntax highlighting of bat.
Opens selected files directly in your editor at the exact line location.

## Platform Support
- ✅ NixOS
- ✅ Darwin

## Features
### Core Functionality
- **Live Search**: Real-time text search with instant results
- **Enhanced Preview**: Syntax-highlighted file preview with context
- **Editor Integration**: Opens files at exact line in your preferred editor
- **Smart Filtering**: Excludes common build artifacts and dependency folders
- **Directory Validation**: Comprehensive error checking and user feedback

### User Experience
- **Colorized Output**: Rich terminal colors for better readability
- **Interactive Help**: Built-in help system (`nviml --help`)
- **Progress Indicators**: Clear search status and navigation hints
- **Error Handling**: Graceful failure with informative error messages
- **Dependency Checking**: Validates all required tools before execution

### Advanced Options
- **Flexible Arguments**: Full ripgrep argument passthrough
- **Custom File Types**: Support for custom file type definitions
- **Hidden Files**: Optional search through hidden files
- **Symlink Following**: Automatic symlink resolution
- **Live Reload**: Dynamic search updating with Ctrl-R

## Implementation
- **Language**: Bash (with strict error handling)
- **Source**: ./nviml (executable shell script)
- **Type**: Interactive command-line utility
- **Dependencies**: ripgrep, fzf, bat, neovim (system)
- **Build**: stdenv.mkDerivation with makeWrapper

## Architecture
### Script Structure
- Modular function-based design
- Comprehensive error handling with `set -euo pipefail`
- Color-coded output for different message types
- Dependency validation before execution
- Argument parsing with directory detection

### Integration Method
- Uses `makeWrapper` to bundle dependencies into PATH
- Self-contained executable with all tools available
- No runtime dependency resolution needed
- Works independently of system package management

## Usage Examples
### Basic Search
```bash
nviml                       # Search current directory
nviml ~/projects            # Search specific directory
nviml --help               # Show comprehensive help
```

### Advanced Filtering
```bash
nviml -t py                 # Search only Python files
nviml -g "*.js"             # Search only JavaScript files
nviml -g "*.{ts,tsx}"       # Search TypeScript files
nviml --type-add 'web:*.{html,css,js}' -t web
                            # Define and use custom file types
```

### Search Patterns
```bash
nviml "function.*render"    # Regex search for render functions
nviml -i "ERROR"            # Case-insensitive search
nviml -w "TODO"             # Whole word search
nviml -A 3 -B 3 "import"    # Search with context lines
```

## Interactive Features
### Key Bindings (in fzf)
- **Enter**: Open file at matching line in editor
- **Ctrl-C / Esc**: Exit without opening file
- **Up/Down**: Navigate through search results
- **Page Up/Down**: Fast navigation through results
- **Ctrl-/**: Toggle preview window visibility
- **Ctrl-U/D**: Scroll preview window up/down
- **Ctrl-R**: Reload search with current parameters

### Visual Elements
- **Header Bar**: Shows current operation and key bindings
- **Search Prompt**: Customized prompt with visual indicators
- **Preview Window**: Syntax-highlighted file content with line highlighting
- **Progress Info**: Inline information about search state
- **Border Styling**: Attractive borders and visual separation

## How It Works
### Search Pipeline
1. **Validation**: Check dependencies and validate search directory
2. **Configuration**: Parse arguments and configure ripgrep options
3. **Search Execution**: Run ripgrep with optimized parameters
4. **Interactive Selection**: Pipe results to fzf with enhanced UI
5. **File Opening**: Launch editor with file and line number

### Smart Defaults
- **File Filtering**: Automatically excludes `.git/`, `node_modules/`, minified files
- **Search Options**: Enables smart case, hidden files, symlink following
- **Editor Detection**: Uses `$EDITOR` environment variable with nvim fallback
- **Error Recovery**: Graceful handling of cancelled searches and missing files

## Common Use Cases
### Development Workflows
- **Function Discovery**: Find function definitions across large codebases
- **Error Investigation**: Search for error messages and stack traces
- **Code Exploration**: Navigate unfamiliar codebases efficiently
- **Refactoring Support**: Locate all instances of variables/functions
- **Documentation Search**: Find comments and documentation strings

### Code Review & Debugging
- **Pattern Analysis**: Search for specific code patterns or anti-patterns
- **Dependency Tracking**: Find import/require statements
- **Configuration Hunting**: Locate configuration files and settings
- **Log Analysis**: Search through log files with syntax highlighting
- **Migration Tasks**: Find deprecated API usage across projects

## Configuration & Integration
### Module Enablement
```nix
# Direct enablement
myconfig.programs.nviml.enable = true;

# Automatic with engineer feature
myconfig.features.engineer.enable = true;  # includes nviml
```

### Environment Configuration
```bash
# Set preferred editor (defaults to nvim)
export EDITOR="code"        # VS Code
export EDITOR="vim"         # Vim
export EDITOR="emacs"       # Emacs

# Create shell alias for convenience
alias lg="nviml"            # Short alias
alias search="nviml"        # Descriptive alias
```

## Performance & Optimization
### Search Performance
- **Ripgrep Speed**: Leverages ripgrep's high-performance text search
- **Smart Exclusions**: Skips binary files and common build artifacts
- **Parallel Processing**: Multi-threaded search across file tree
- **Memory Efficiency**: Streams results without loading entire files

### UI Responsiveness
- **Instant Preview**: Real-time preview updates as you navigate
- **Lazy Loading**: Previews only render when needed
- **Efficient Rendering**: Optimized fzf configuration for large result sets
- **Progressive Search**: Results appear as they're found

## Dependencies & Requirements
### Required Tools
- **ripgrep (rg)**: Fast text search engine
- **fzf**: Command-line fuzzy finder
- **bat**: Syntax highlighting for file preview
- **neovim**: Text editor (system installation, not provided)

### Optional Enhancements
- **git**: For repository-aware searching
- **fd**: Alternative file finder (ripgrep can use git ignore)
- **delta**: Enhanced diff highlighting in git repositories

## Error Handling & Troubleshooting
### Common Issues
- **Missing Dependencies**: Clear error messages with installation hints
- **Permission Errors**: Readable error messages for directory access
- **Editor Not Found**: Automatic fallback with warning messages
- **Empty Results**: Graceful handling of no-match scenarios

### Debug Information
- **Verbose Mode**: Shows search parameters and configuration
- **Dependency Check**: Validates all required tools before execution
- **Path Resolution**: Displays absolute paths for clarity
- **Exit Codes**: Proper exit codes for script integration

## Security Considerations
- **Path Validation**: Prevents directory traversal attacks
- **Argument Sanitization**: Safe handling of user-provided arguments
- **Permission Respect**: Honors file system permissions
- **No Privilege Escalation**: Runs with user permissions only

## Tips & Best Practices
### Effective Searching
- Use file type filters (`-t`) for faster, more relevant results
- Combine with git for repository-aware searching
- Set `$EDITOR` environment variable for seamless editor integration
- Use regex patterns for complex search requirements

### Performance Tips
- Search specific directories rather than entire filesystem
- Use appropriate file type filters to reduce search scope
- Exclude large binary directories with glob patterns
- Consider using ripgrep's built-in parallelism settings

### Integration Ideas
- Create shell aliases for common search patterns
- Integrate with git hooks for pre-commit searches
- Use in CI/CD pipelines for code quality checks
- Combine with other terminal tools in custom workflows
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;

  program = pkgs.stdenv.mkDerivation {
    name = "nviml";
    src = ./.;

    nativeBuildInputs = [pkgs.makeWrapper];

    installPhase = ''
      mkdir -p $out/bin
      cp nviml $out/bin/
      chmod +x $out/bin/nviml

      wrapProgram $out/bin/nviml \
        --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.ripgrep pkgs.fzf pkgs.bat]}
    '';
  };
in
  delib.module {
    name = "programs.nviml";

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
