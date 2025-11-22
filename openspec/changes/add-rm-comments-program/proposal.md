# Proposal: Add rm-comments Unified Comment Removal Program

## Why

Code comment removal is a common need for various workflows including:
- Minification and code obfuscation for production deployments
- Reducing repository size and improving clone times
- Preparing code for analysis tools that don't handle comments well
- Cleaning up generated code or legacy codebases
- Creating documentation-free code snippets for sharing

Currently, there's no unified tool in the dotfiles repository that can strip comments across multiple programming languages while preserving important compiler directives and build annotations. This proposal addresses GitHub issue #172 by implementing a single, unified comment removal utility with language-specific backends.

## What Changes

- **New custom program**: `rm-comments` - A unified CLI tool with multi-language support
  - **Main interface**: Bash wrapper that auto-detects language or accepts explicit `--lang` flag
  - **Supported languages**: Go, Python, Rust, TypeScript/TSX
  - **Language detection**: Automatic based on file extensions (.go, .py, .rs, .ts, .tsx)
  - **Unified flags**: Consistent interface with language-specific options passed through

- **Implementation approach**:
  - Single Nix derivation containing all implementations
  - Bash wrapper (`rm-comments`) as the main entry point
  - Four language-specific backends (bundled but not directly exposed):
    - **Go backend**: Removes comments while preserving `//go:`, `//go:build`, `// +build`, line directives, and cgo preambles
    - **Python backend**: Removes comments and docstrings while preserving shebangs (`#!/...`)
    - **Rust backend**: Handles nested block comments, raw strings, and byte strings
    - **TypeScript/TSX backend**: Removes comments including JSX comment expressions (`{/* ... */}`)

- **CLI Interface**:
  ```bash
  rm-comments [options] <path>

  Options:
    --lang <language>        Explicitly specify language (go|python|rust|tsx)
                             Auto-detected from file extensions if not specified
    --write, -w              Write changes to files (default: dry-run)
    --quiet, -q              Suppress per-file output

    Go-specific options:
    --remove-directives      Also remove compiler directives (dangerous)
    --skip-tests             Skip *_test.go files
    --include-vendor         Process vendor/ directories
  ```

- **Integration**:
  - Add to engineer feature by default for development workflows
  - Follow existing custom program patterns (delib.module with platform sections)
  - Single program installation: `myconfig.programs.rm-comments.enable = true`

## Impact

### Affected Specs
- **NEW**: `comment-removal` - Core capability specification for the unified multi-language comment removal tool

### Affected Code
- **New files**:
  - `modules/programs/rm-comments/` - New program directory
  - `modules/programs/rm-comments/default.nix` - Main Nix module with single derivation
  - `modules/programs/rm-comments/rm-comments.sh` - Bash wrapper script (main entry point)
  - `modules/programs/rm-comments/go/` - Go implementation
  - `modules/programs/rm-comments/python/` - Python implementation
  - `modules/programs/rm-comments/rust/` - Rust implementation
  - `modules/programs/rm-comments/tsx/` - TypeScript/TSX implementation

- **Modified files**:
  - `modules/features/engineer.nix` - Add `rm-comments.enable = true`

### User Impact
- Users with engineer feature enabled will have access to single `rm-comments` command
- Auto-detection makes it easy to use: `rm-comments src/` works on mixed-language codebases
- Explicit `--lang` flag available for ambiguous cases or piped input
- Safe dry-run mode by default (requires `--write` flag for actual changes)
- Preserves critical compiler directives to prevent breaking builds
- No breaking changes to existing functionality

### Technical Considerations
- Single derivation builds all language implementations together
- Bash wrapper handles language detection and argument routing
- Uses language-native parsing where possible (go/ast, Python tokenize, TypeScript compiler API)
- Rust implementation uses manual state machine for robust comment detection
- All backends skip vendor/node_modules directories and provide recursive processing
- File permissions preserved during write operations
- Cross-platform support (NixOS + Darwin)
