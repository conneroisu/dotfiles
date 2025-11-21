/**
# Program Module: nvimf (Neovim Fuzzy File Opener)

## Description
A lightweight interactive fuzzy file finder that provides instant file selection
with syntax-highlighted preview. Opens selected files directly in Neovim with
a streamlined, efficient workflow.

## Platform Support
- ✅ NixOS
- ✅ Darwin

## Features
### Core Functionality
- **Fuzzy File Finding**: Fast file search with instant filtering
- **Syntax-Highlighted Preview**: Rich file preview with bat integration
- **Direct Editor Launch**: Opens files immediately in Neovim
- **Smart Filtering**: Automatically excludes common build artifacts
- **Graceful Cancellation**: Clean exit without side effects

### User Experience
- **Interactive Interface**: Clean fzf-based file selection
- **Colorized Preview**: Syntax highlighting for better readability
- **Help System**: Built-in help with `nvimf --help`
- **Error Handling**: Comprehensive validation and error messages
- **Directory Support**: Works in current or specified directory

## Implementation
- **Language**: Bash (with strict error handling)
- **Source**: ./nvimf (executable shell script)
- **Type**: Interactive command-line utility
- **Dependencies**: fzf, bat, neovim, fd (optional)
- **Build**: stdenv.mkDerivation with makeWrapper

## Architecture
### Script Structure
- Clean function-based design
- Strict error handling with `set -euo pipefail`
- Dependency validation before execution
- Support for both fd and find fallback
- Graceful handling of empty selections

### Integration Method
- Uses `makeWrapper` to bundle dependencies into PATH
- Self-contained executable with all tools available
- No runtime dependency resolution needed
- Works independently of system package management

## Usage Examples
### Basic Usage
```bash
nvimf                       # Open file picker in current directory
nvimf ~/projects            # Open file picker in specific directory
nvimf --help               # Show help information
```

### Workflow Integration
```bash
# Quick file editing
nvimf                       # Select and edit any file

# Project navigation
cd ~/myproject && nvimf     # Browse and edit project files

# Multi-directory workflow
nvimf ~/configs             # Edit config files
nvimf ~/projects/app        # Edit application files
```

## Interactive Features
### Key Bindings (in fzf)
- **Enter**: Open selected file in Neovim
- **Ctrl-C / ESC**: Exit without opening file
- **Up/Down**: Navigate through file list
- **Ctrl-/**: Toggle preview window visibility
- **Ctrl-U/D**: Scroll preview window up/down
- **Type to filter**: Fuzzy search file names

### Visual Elements
- **Header Bar**: Shows key bindings and current operation
- **Preview Window**: Syntax-highlighted file content (60% of screen)
- **Border Styling**: Clean borders for visual clarity
- **Prompt**: Clear indication of current action

## How It Works
### Selection Pipeline
1. **Validation**: Check dependencies and validate directory
2. **File Discovery**: Scan directory with fd or find
3. **Interactive Selection**: Present files in fzf with preview
4. **File Opening**: Launch Neovim with selected file

### Smart Defaults
- **File Filtering**: Excludes .git/, node_modules/, .cache/, dist/, build/
- **Preview Limit**: Shows first 500 lines for fast rendering
- **Graceful Exit**: Returns exit code 0 on cancellation
- **Editor Fallback**: Uses Neovim directly (no $EDITOR detection needed)

## Common Use Cases
### Development Workflows
- **Quick File Access**: Rapidly open any file in a project
- **Configuration Editing**: Navigate dotfiles and config directories
- **Project Exploration**: Browse unfamiliar codebases efficiently
- **Context Switching**: Jump between different file types quickly

### Daily Operations
- **Note Taking**: Quick access to markdown notes
- **Log Review**: Find and open log files with preview
- **Documentation**: Navigate documentation directories
- **Script Editing**: Select and edit shell scripts

## Configuration & Integration
### Module Enablement
```nix
# Direct enablement
myconfig.programs.nvimf.enable = true;

# Automatic with engineer feature
myconfig.features.engineer.enable = true;  # includes nvimf
```

### Shell Integration
```bash
# Create convenient aliases
alias nf="nvimf"           # Short alias
alias edit="nvimf"         # Descriptive alias
alias fe="nvimf"           # File edit

# Project-specific shortcuts
alias editdot="nvimf ~/.config"
alias editproj="nvimf ~/projects"
```

## Performance & Optimization
### File Discovery
- **Fast Scanning**: Uses fd when available for parallel scanning
- **Fallback Support**: Uses find when fd is not available
- **Smart Exclusions**: Skips common build directories
- **No Hidden Cost**: Respects .gitignore patterns with fd

### UI Responsiveness
- **Instant Preview**: Real-time preview as you navigate
- **Efficient Rendering**: Limited preview lines for fast display
- **Smooth Navigation**: Optimized fzf configuration
- **Fast Filtering**: Fuzzy search without lag

## Dependencies & Requirements
### Required Tools
- **fzf**: Command-line fuzzy finder for file selection
- **bat**: Syntax highlighting for file preview
- **neovim**: Text editor for opening files

### Optional Enhancements
- **fd**: Fast file finder (fallback to find if not available)
- **git**: For repository-aware file filtering

## Error Handling & Troubleshooting
### Common Scenarios
- **No File Selected**: Exits gracefully with informative message
- **Invalid Directory**: Clear error message with directory path
- **Missing Dependencies**: Validates all tools before execution
- **Permission Errors**: Readable error messages for access issues

### Debug Information
- **Dependency Check**: Validates fzf, bat, nvim before running
- **Path Validation**: Ensures directory exists and is accessible
- **Clear Messages**: All errors include context and suggestions
- **Exit Codes**: Proper exit codes for script integration

## Security Considerations
- **Path Safety**: Validates directory existence before access
- **Permission Respect**: Honors file system permissions
- **No Execution**: Only opens files for editing, doesn't execute
- **User Control**: Requires explicit file selection

## Tips & Best Practices
### Effective Usage
- Use in project root directories for quick file access
- Combine with cd for multi-directory workflows
- Create shell aliases for frequently accessed directories
- Leverage preview to verify file contents before opening

### Integration Ideas
- Add to shell aliases for common directories
- Use in git hooks for selecting files to review
- Integrate with tmux for quick pane-based editing
- Combine with other CLI tools in custom scripts

## Comparison with Alternatives
### vs. Direct nvim
- **Faster**: No manual path typing or tab completion
- **Preview**: See file contents before opening
- **Fuzzy**: Find files without exact names

### vs. nvim with telescope/fzf plugin
- **Simpler**: Works from shell, no Neovim configuration needed
- **Universal**: Same interface across all projects
- **Lightweight**: No plugin overhead or configuration

### vs. nviml (live grep)
- **Complementary**: nvimf for file names, nviml for content search
- **Faster**: When you know the file name (or part of it)
- **Simpler**: Fewer options, focused on file selection

## Related Tools
- **nviml**: Live grep search with Neovim integration
- **fzf**: Underlying fuzzy finder technology
- **bat**: Syntax highlighting for preview
- **fd**: Fast file discovery (optional)
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;

  program = pkgs.stdenv.mkDerivation {
    name = "nvimf";
    src = ./.;

    nativeBuildInputs = with pkgs; [
      makeWrapper
      fzf
      bat
      neovim
      fd
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp nvimf $out/bin/
      chmod +x $out/bin/nvimf

      wrapProgram $out/bin/nvimf \
        --prefix PATH : ${pkgs.lib.makeBinPath [
        pkgs.fzf
        pkgs.bat
        pkgs.neovim
        pkgs.fd
      ]}
    '';
  };
in
  delib.module {
    name = "programs.nvimf";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [program];
    };

    darwin.ifEnabled = {
      environment.systemPackages = [program];
    };
  }
