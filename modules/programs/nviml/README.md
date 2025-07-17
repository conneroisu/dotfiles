# nviml - Neovim Live Search

A sophisticated terminal-based live grep tool that combines the speed of ripgrep with the interactivity of fzf and the syntax highlighting of bat. Search through codebases with real-time preview and open files directly in your editor.

## Features

- 🔍 **Live Search** - Real-time text search with instant results
- 👀 **Enhanced Preview** - Syntax-highlighted file preview with context
- 🎯 **Editor Integration** - Opens files at exact line in your preferred editor
- 🧠 **Smart Filtering** - Excludes common build artifacts and dependency folders
- 🎨 **Rich UI** - Colorized output with intuitive key bindings
- ⚡ **High Performance** - Leverages ripgrep's multi-threaded search engine

## Installation

Enable via NixOS/Darwin configuration:

```nix
# Direct enablement
myconfig.programs.nviml.enable = true;

# Or automatically with engineer feature
myconfig.features.engineer.enable = true;
```

## Usage

### Basic Usage
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

## Key Bindings

| Key | Action |
|-----|--------|
| `Enter` | Open file at matching line in editor |
| `Ctrl-C` / `Esc` | Exit without opening file |
| `Up/Down` | Navigate through search results |
| `Page Up/Down` | Fast navigation through results |
| `Ctrl-/` | Toggle preview window visibility |
| `Ctrl-U/D` | Scroll preview window up/down |
| `Ctrl-R` | Reload search with current parameters |

## Environment Configuration

```bash
# Set preferred editor (defaults to nvim)
export EDITOR="code"        # VS Code
export EDITOR="vim"         # Vim
export EDITOR="emacs"       # Emacs

# Create shell aliases for convenience
alias lg="nviml"            # Short alias
alias search="nviml"        # Descriptive alias
```

## Dependencies

- **ripgrep (rg)** - Fast text search engine
- **fzf** - Command-line fuzzy finder  
- **bat** - Syntax highlighting for file preview
- **neovim** - Text editor (system installation)

All dependencies except neovim are automatically bundled with the module.

## Tips & Best Practices

- Use file type filters (`-t`) for faster, more relevant results
- Set `$EDITOR` environment variable for seamless editor integration
- Search specific directories rather than entire filesystem for better performance
- Use regex patterns for complex search requirements
- Combine with git for repository-aware searching

## Common Use Cases

- **Function Discovery** - Find function definitions across large codebases
- **Error Investigation** - Search for error messages and stack traces
- **Code Exploration** - Navigate unfamiliar codebases efficiently
- **Refactoring Support** - Locate all instances of variables/functions
- **Documentation Search** - Find comments and documentation strings

## Performance

nviml is optimized for speed and efficiency:

- Leverages ripgrep's high-performance multi-threaded search
- Automatically excludes `.git/`, `node_modules/`, and minified files
- Streams results without loading entire files into memory
- Real-time preview updates as you navigate results

## Contributing

This is part of the [Denix dotfiles framework](https://github.com/conneroisu/dotfiles). Contributions welcome!