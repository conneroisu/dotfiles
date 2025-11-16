# Specification: Comment Removal

## ADDED Requirements

### Requirement: Unified Command Interface
The system SHALL provide a single `rm-comments` command that handles comment removal for multiple programming languages through a unified interface.

#### Scenario: Single entry point command
- **GIVEN** the rm-comments program is installed
- **WHEN** a user runs `rm-comments --help`
- **THEN** usage information is displayed
- **AND** supported languages are listed (go, python, rust, tsx)
- **AND** common flags and language-specific options are documented

#### Scenario: Auto-detect language from extension
- **GIVEN** a file with a supported extension (.go, .py, .rs, .ts, .tsx)
- **WHEN** `rm-comments <file>` is executed without `--lang` flag
- **THEN** the language is automatically detected from the file extension
- **AND** the appropriate language backend is invoked

#### Scenario: Explicit language override
- **GIVEN** any file regardless of extension
- **WHEN** `rm-comments --lang <language> <file>` is executed
- **THEN** the specified language backend is used
- **AND** file extension is ignored for language detection

#### Scenario: Mixed language directory processing
- **GIVEN** a directory with files of multiple supported languages
- **WHEN** `rm-comments <directory>` is executed
- **THEN** each file is processed with its appropriate language backend
- **AND** .go files use Go backend
- **AND** .py files use Python backend
- **AND** .rs files use Rust backend
- **AND** .ts and .tsx files use TypeScript backend

### Requirement: Go Comment Removal
The system SHALL remove comments from Go source files while preserving compiler directives and build annotations.

#### Scenario: Remove comments from Go file
- **GIVEN** a Go source file with comments and code
- **WHEN** `rm-comments file.go` is executed without `--write` flag
- **THEN** the tool displays what changes would be made without modifying the file
- **AND** output indicates "would update: file.go" if comments exist

#### Scenario: Write changes to Go file
- **GIVEN** a Go source file with comments
- **WHEN** `rm-comments --write file.go` is executed
- **THEN** comments are removed from the file
- **AND** the file is updated in-place with original permissions preserved
- **AND** output indicates "updated: file.go"

#### Scenario: Preserve compiler directives in Go
- **GIVEN** a Go file with `//go:build`, `// +build`, `//go:generate`, or cgo directives
- **WHEN** `rm-comments --write file.go` is executed without `--remove-directives`
- **THEN** compiler directives are preserved
- **AND** ordinary comments are removed
- **AND** the code remains compilable

#### Scenario: Remove all comments including directives
- **GIVEN** a Go file with compiler directives and comments
- **WHEN** `rm-comments --write --remove-directives file.go` is executed
- **THEN** all comments including compiler directives are removed

#### Scenario: Skip test files in Go
- **GIVEN** a directory with both regular .go and *_test.go files
- **WHEN** `rm-comments --skip-tests --write <directory>` is executed
- **THEN** only non-test .go files are processed
- **AND** *_test.go files are skipped

#### Scenario: Include vendor directory in Go
- **GIVEN** a directory with vendor/ subdirectory
- **WHEN** `rm-comments --include-vendor --write <directory>` is executed
- **THEN** .go files in vendor/ are also processed

### Requirement: Python Comment Removal
The system SHALL remove comments and docstrings from Python source files while preserving shebangs.

#### Scenario: Remove comments from Python file
- **GIVEN** a Python source file with comments and docstrings
- **WHEN** `rm-comments file.py` is executed
- **THEN** the tool displays what changes would be made without modifying the file

#### Scenario: Preserve shebang in Python
- **GIVEN** a Python file starting with `#!/usr/bin/env python3` or similar shebang
- **WHEN** `rm-comments file.py` is executed
- **THEN** the shebang line is preserved
- **AND** all other comments and docstrings are removed

#### Scenario: Remove docstrings from Python
- **GIVEN** a Python file with module, class, and function docstrings
- **WHEN** `rm-comments file.py` is executed
- **THEN** all docstrings are removed
- **AND** the code structure remains intact

### Requirement: Rust Comment Removal
The system SHALL remove comments from Rust source files while handling nested block comments and string literals.

#### Scenario: Remove line comments from Rust
- **GIVEN** a Rust file with line comments (`//`)
- **WHEN** `rm-comments file.rs` is executed
- **THEN** line comments are removed
- **AND** code remains syntactically valid

#### Scenario: Handle nested block comments in Rust
- **GIVEN** a Rust file with nested block comments (`/* /* nested */ */`)
- **WHEN** `rm-comments file.rs` is executed
- **THEN** all nested block comments are correctly removed
- **AND** comment nesting levels are properly tracked

#### Scenario: Preserve raw strings in Rust
- **GIVEN** a Rust file with raw string literals like `r#"text"#` or `r##"text"##`
- **WHEN** `rm-comments file.rs` is executed
- **THEN** raw string contents are preserved unchanged
- **AND** comment-like sequences inside raw strings are not treated as comments

### Requirement: TypeScript/TSX Comment Removal
The system SHALL remove comments from TypeScript and TSX files including JSX comment expressions.

#### Scenario: Remove TypeScript comments
- **GIVEN** a TypeScript file with line and block comments
- **WHEN** `rm-comments file.ts` is executed
- **THEN** all JavaScript/TypeScript comments are removed
- **AND** code remains syntactically valid

#### Scenario: Remove JSX comment expressions
- **GIVEN** a TSX file with JSX comment expressions like `{/* comment */}`
- **WHEN** `rm-comments file.tsx` is executed
- **THEN** JSX comment expressions are completely removed
- **AND** no empty `{}` braces are left behind
- **AND** JSX structure remains valid

#### Scenario: Handle mixed TypeScript and JSX
- **GIVEN** a TSX file with both TypeScript comments and JSX comment expressions
- **WHEN** `rm-comments file.tsx` is executed
- **THEN** all comment types are removed
- **AND** both TypeScript and JSX code remain valid

### Requirement: Recursive Directory Processing
The system SHALL recursively process directories and handle multiple files efficiently.

#### Scenario: Recursive processing of directory tree
- **GIVEN** a directory tree with multiple files of supported languages
- **WHEN** `rm-comments <directory>` is executed
- **THEN** all files with supported extensions in the directory and subdirectories are processed
- **AND** each file is processed with its appropriate language backend

#### Scenario: Skip ignored directories
- **GIVEN** a directory tree containing vendor/, node_modules/, and .direnv/ subdirectories
- **WHEN** `rm-comments <directory>` is executed
- **THEN** vendor/ directories are skipped for Go files (unless --include-vendor is specified)
- **AND** node_modules/ directories are skipped for TypeScript files
- **AND** .direnv/ directories are always skipped

#### Scenario: Output relative paths
- **GIVEN** files being processed in subdirectories
- **WHEN** `rm-comments <directory>` is executed
- **THEN** output shows paths relative to current working directory
- **AND** "Updated: <relative-path>" or "would update: <relative-path>" is shown for each file

### Requirement: Nix Module Integration
The system SHALL provide a Nix module that packages the unified rm-comments tool with all backends for cross-platform deployment.

#### Scenario: Single derivation installation
- **GIVEN** a host configuration
- **WHEN** `myconfig.programs.rm-comments.enable = true` is set
- **THEN** the rm-comments command is available in the system PATH
- **AND** all language backends are bundled and functional
- **AND** the tool works on both NixOS and Darwin platforms

#### Scenario: Enable via engineer feature
- **GIVEN** the engineer feature is enabled in a host configuration
- **WHEN** the system is rebuilt
- **THEN** rm-comments is automatically available
- **AND** the command works with all supported languages

#### Scenario: Cross-platform package availability
- **GIVEN** a NixOS or Darwin system with rm-comments enabled
- **WHEN** a user runs `rm-comments` with any supported language
- **THEN** the command executes successfully
- **AND** all necessary language runtimes and dependencies are available

### Requirement: Safe Defaults
The system SHALL use safe defaults to prevent accidental data loss.

#### Scenario: Dry-run mode by default
- **GIVEN** rm-comments command executed without `--write` or `-w` flag
- **WHEN** the command processes files
- **THEN** no files are modified
- **AND** output shows "would update: <file>" for files with comments
- **AND** summary indicates "Mode: dry-run"

#### Scenario: Preserve file permissions
- **GIVEN** a file with specific permissions (e.g., 0755)
- **WHEN** `rm-comments --write <file>` modifies the file
- **THEN** the original file permissions are preserved

#### Scenario: Quiet mode suppresses per-file output
- **GIVEN** a directory with many files to process
- **WHEN** `rm-comments --quiet <directory>` is executed
- **THEN** per-file processing messages are suppressed
- **AND** only the final summary is shown
- **AND** errors are still displayed

### Requirement: Consistent CLI Interface
The system SHALL provide a consistent command-line interface with clear flag semantics.

#### Scenario: Common flags available for all languages
- **GIVEN** any file of a supported language
- **WHEN** rm-comments is invoked
- **THEN** the following common flags are supported:
  - `--lang <language>`: Explicitly specify language
  - `--write` or `-w`: Write changes to files
  - `--quiet` or `-q`: Suppress per-file output
- **AND** positional argument accepts file or directory path

#### Scenario: Language-specific flags passed through
- **GIVEN** a Go file being processed
- **WHEN** `rm-comments --remove-directives --skip-tests <path>` is executed
- **THEN** Go-specific flags are passed to the Go backend
- **AND** these flags are only valid when processing Go files

#### Scenario: Summary output format
- **GIVEN** any rm-comments variant processes files
- **WHEN** processing completes
- **THEN** a summary is displayed showing:
  - Number of files scanned
  - Number of files changed
  - Mode (write or dry-run)
- **AND** format is consistent across all language backends

### Requirement: Language Detection
The system SHALL accurately detect programming languages from file extensions and route to appropriate backends.

#### Scenario: Detect Go from extension
- **GIVEN** a file with .go extension
- **WHEN** `rm-comments <file.go>` is executed without --lang flag
- **THEN** the Go backend is automatically selected

#### Scenario: Detect Python from extension
- **GIVEN** a file with .py extension
- **WHEN** `rm-comments <file.py>` is executed without --lang flag
- **THEN** the Python backend is automatically selected

#### Scenario: Detect Rust from extension
- **GIVEN** a file with .rs extension
- **WHEN** `rm-comments <file.rs>` is executed without --lang flag
- **THEN** the Rust backend is automatically selected

#### Scenario: Detect TypeScript from extensions
- **GIVEN** a file with .ts or .tsx extension
- **WHEN** `rm-comments <file>` is executed without --lang flag
- **THEN** the TypeScript backend is automatically selected

#### Scenario: Language detection failure with helpful error
- **GIVEN** a file with unsupported or no extension
- **WHEN** `rm-comments <file>` is executed without --lang flag
- **THEN** an error message is displayed indicating language could not be detected
- **AND** the error suggests using the --lang flag
- **AND** exit code is non-zero

### Requirement: Error Handling
The system SHALL handle errors gracefully and provide clear error messages.

#### Scenario: Invalid path provided
- **GIVEN** a path that does not exist
- **WHEN** `rm-comments <invalid-path>` is executed
- **THEN** an error message is displayed
- **AND** exit code is non-zero
- **AND** error indicates the path was not found

#### Scenario: File processing error
- **GIVEN** a file that cannot be parsed (syntax error)
- **WHEN** `rm-comments <invalid-file>` is executed
- **THEN** an error message indicates which file failed
- **AND** the error includes parsing details
- **AND** exit code is non-zero

#### Scenario: Permission denied on write
- **GIVEN** a file without write permissions
- **WHEN** `rm-comments --write <file>` is executed
- **THEN** an error message indicates permission denied
- **AND** exit code is non-zero
- **AND** no partial changes are made

#### Scenario: Invalid language specified
- **GIVEN** an invalid language name
- **WHEN** `rm-comments --lang invalid-lang <file>` is executed
- **THEN** an error message lists supported languages
- **AND** exit code is non-zero
