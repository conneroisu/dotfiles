# Design: rm-comments Unified Comment Removal Tool

## Context

The rm-comments program addresses the need for reliable comment removal across multiple programming languages through a single, unified command-line interface. The implementation is based on proven code from GitHub issue #172, which provides battle-tested implementations in Go, Python, Rust, and TypeScript/TSX.

### Constraints
- Must provide a single user-facing command (`rm-comments`)
- Must preserve compiler directives and build annotations (e.g., `//go:build`, `#cgo`)
- Must handle language-specific edge cases (nested comments in Rust, JSX in TSX, raw strings)
- Must be cross-platform (NixOS + Darwin)
- Must follow existing dotfiles custom program patterns
- Should default to dry-run mode to prevent accidental data loss
- All implementations must be bundled in a single Nix derivation

### Stakeholders
- Developers using the engineer feature for code manipulation
- CI/CD pipelines that need to minify or strip documentation
- Users working with code generation tools
- Users with mixed-language codebases

## Goals / Non-Goals

### Goals
- Provide a single `rm-comments` command that handles multiple languages
- Auto-detect language from file extensions
- Support explicit language selection via `--lang` flag
- Preserve critical compiler directives that affect builds
- Support both single-file and recursive directory processing
- Maintain consistent CLI interface across all languages
- Integrate seamlessly into existing dotfiles workflow
- Default to dry-run mode with explicit `--write` flag for changes
- Bundle all implementations in a single derivation for atomic installation

### Non-Goals
- Support for additional languages beyond the initial four (can be added later)
- IDE integration or real-time comment stripping
- Configuration file support (CLI flags are sufficient)
- Comment restoration or undo functionality
- Separate binaries for each language (unified interface preferred)

## Decisions

### Decision 1: Unified CLI with Bash Wrapper

**Choice**: Implement a single `rm-comments` command (bash wrapper) that dispatches to language-specific backends rather than separate commands per language.

**Rationale**:
- **Simpler user experience**: One command to learn, not four
- **Auto-detection**: Users don't need to specify language for most cases
- **Mixed codebases**: Can process entire directories with multiple languages
- **Cleaner namespace**: Single binary in PATH, not four
- **Atomic installation**: Enable/disable all languages together

**Alternatives Considered**:
- **Four separate commands** (`rm-comments-go`, `rm-comments-py`, etc.): More explicit but clutters PATH and requires users to know which command to use. Rejected for poor UX.
- **Symlinks approach**: Create symlinks for language-specific names. Adds complexity without clear benefit. Rejected.

### Decision 2: Language Detection Strategy

**Choice**: Auto-detect language from file extensions (.go, .py, .rs, .ts, .tsx) with explicit `--lang` flag as override.

**Rationale**:
- **Most common case**: Users point at files/directories and tool "just works"
- **Explicit override available**: For edge cases or ambiguous situations
- **Simple implementation**: Extension matching is straightforward and fast
- **Predictable behavior**: Clear rules for which backend handles which files

**Detection Rules**:
```
.go     → Go backend
.py     → Python backend
.rs     → Rust backend
.ts     → TypeScript backend
.tsx    → TypeScript backend (same as .ts)
```

**Alternatives Considered**:
- **Content-based detection**: Parse file headers or syntax. Too slow and complex. Rejected.
- **Always require --lang flag**: Poor UX for common case. Rejected.
- **Magic file type detection**: Over-engineered. Rejected.

### Decision 3: Single Nix Derivation Architecture

**Choice**: Package all four language implementations plus the bash wrapper in one derivation using `pkgs.stdenv.mkDerivation`.

**Rationale**:
- **Atomic installation**: All backends available when program is enabled
- **Simpler module definition**: One package, not four
- **Consistent versioning**: All backends updated together
- **Reduced complexity**: Single build process

**Build Structure**:
```nix
pkgs.stdenv.mkDerivation {
  name = "rm-comments";

  buildInputs = [
    pkgs.go           # For Go backend
    pkgs.python3      # For Python backend
    pkgs.rustc cargo  # For Rust backend
    pkgs.nodejs       # For TypeScript backend
  ];

  buildPhase = ''
    # Build Go backend
    cd go && go build -o ../rm-comments-go-backend main.go

    # Build Rust backend
    cd rust && cargo build --release

    # Build TypeScript backend
    cd tsx && npm install && npm run build

    # Python backend is interpreted (no build needed)
  '';

  installPhase = ''
    mkdir -p $out/bin $out/libexec/rm-comments

    # Install backends
    cp rm-comments-go-backend $out/libexec/rm-comments/
    cp rust/target/release/rm-comments-rs-backend $out/libexec/rm-comments/
    cp tsx/dist/remove-comments.js $out/libexec/rm-comments/
    cp python/main.py $out/libexec/rm-comments/rm-comments-py-backend

    # Install main wrapper
    cp rm-comments.sh $out/bin/rm-comments
    chmod +x $out/bin/rm-comments
  '';
}
```

**Alternatives Considered**:
- **Separate derivations per language**: More modular but complicates installation and module definition. Rejected for complexity.
- **Language-specific builders** (buildGoModule, buildRustPackage, etc.): Can't combine into single derivation easily. Rejected.

### Decision 4: Bash Wrapper Implementation

**Choice**: Main `rm-comments` command is a bash script that:
1. Parses common flags (--lang, --write, --quiet)
2. Detects language from file extension or --lang flag
3. Routes to appropriate backend in $out/libexec/rm-comments/
4. Passes through language-specific flags

**Rationale**:
- **Simple orchestration**: Bash perfect for argument routing
- **No runtime dependencies**: Bash available on all Unix systems
- **Easy to understand**: Clear logic flow
- **Flexible flag passing**: Easy to add language-specific options

**Wrapper Pseudocode**:
```bash
#!/usr/bin/env bash

# Parse flags
LANG=""
WRITE=false
QUIET=false
LANG_SPECIFIC_FLAGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --lang) LANG="$2"; shift 2;;
    --write|-w) WRITE=true; shift;;
    --quiet|-q) QUIET=true; shift;;
    --remove-directives|--skip-tests|--include-vendor)
      LANG_SPECIFIC_FLAGS+=("$1"); shift;;
    *) PATH_ARG="$1"; shift;;
  esac
done

# Auto-detect language if not specified
if [[ -z "$LANG" ]]; then
  case "$PATH_ARG" in
    *.go) LANG="go";;
    *.py) LANG="python";;
    *.rs) LANG="rust";;
    *.ts|*.tsx) LANG="tsx";;
    *) # Directory: detect from contents
       LANG=$(detect_from_directory "$PATH_ARG")
       ;;
  esac
fi

# Route to backend
LIBEXEC="$(dirname "$0")/../libexec/rm-comments"
case "$LANG" in
  go)
    "$LIBEXEC/rm-comments-go-backend" \
      ${WRITE:+--write} ${QUIET:+--quiet} \
      "${LANG_SPECIFIC_FLAGS[@]}" "$PATH_ARG"
    ;;
  python)
    python3 "$LIBEXEC/rm-comments-py-backend" "$PATH_ARG"
    ;;
  rust)
    "$LIBEXEC/rm-comments-rs-backend" "$PATH_ARG"
    ;;
  tsx)
    node "$LIBEXEC/rm-comments-tsx-backend.js" "$PATH_ARG"
    ;;
  *)
    echo "Error: Could not detect language. Use --lang flag."
    exit 1
    ;;
esac
```

**Alternatives Considered**:
- **Python wrapper**: Adds Python runtime dependency. Rejected.
- **Go wrapper**: Overkill for simple routing logic. Rejected.

### Decision 5: Language-Specific Implementation Choices

**Choice**: Use language-native parsers for each backend:
- **Go**: `go/ast` and `go/parser` from standard library
- **Python**: `tokenize` module from standard library
- **TypeScript**: `typescript` compiler API
- **Rust**: Manual state machine (proven code from issue #172)

**Rationale**:
- **Highest reliability**: Official parsers handle all edge cases
- **No external dependencies** (except TypeScript): Simplifies builds
- **Proven implementations**: Code from issue #172 is battle-tested

### Decision 6: Directory Processing Behavior

**Choice**: When given a directory:
- Process all files matching supported extensions recursively
- Skip common ignore patterns: `vendor/`, `node_modules/`, `.direnv/`
- Report per-file results (suppressible with `--quiet`)
- Final summary shows total scanned/changed

**Rationale**:
- **Most common use case**: Users want to process entire source trees
- **Sensible defaults**: Skip dependencies and build artifacts
- **Visibility**: Show what's happening unless explicitly quieted

## Architecture

### System Overview

```
┌─────────────────────────────────────────────┐
│         rm-comments (Bash Wrapper)          │
│  - Parse CLI flags                          │
│  - Detect language from extension or --lang │
│  - Route to appropriate backend             │
└─────────────────┬───────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │  Language Router  │
        └────────┬──────────┘
                 │
     ┌───────────┼───────────┬────────────┐
     │           │           │            │
┌────▼────┐ ┌───▼────┐ ┌────▼─────┐ ┌───▼─────┐
│   Go    │ │ Python │ │   Rust   │ │   TSX   │
│ Backend │ │Backend │ │ Backend  │ │ Backend │
│         │ │        │ │          │ │         │
│go/ast   │ │tokenize│ │  State   │ │   TS    │
│parser   │ │ module │ │ Machine  │ │Compiler │
└─────────┘ └────────┘ └──────────┘ └─────────┘
```

### Directory Structure

```
modules/programs/rm-comments/
├── default.nix                 # Nix module (delib.module)
├── rm-comments.sh              # Main bash wrapper
├── go/
│   ├── main.go                 # Go backend implementation
│   └── go.mod
├── python/
│   └── main.py                 # Python backend implementation
├── rust/
│   ├── src/main.rs             # Rust backend implementation
│   └── Cargo.toml
└── tsx/
    ├── remove-comments.ts      # TypeScript backend implementation
    ├── package.json
    └── tsconfig.json
```

### CLI Interface

```
rm-comments [options] <path>

Common Options:
  --lang <language>     Explicitly specify language (go|python|rust|tsx)
                        Auto-detected from file extensions if not specified
  --write, -w           Write changes to files (default: dry-run)
  --quiet, -q           Suppress per-file output, show only summary

Go-Specific Options (only when processing Go files):
  --remove-directives   Also remove compiler directives (//go:*, cgo, etc.)
                        WARNING: May break builds
  --skip-tests          Skip files matching *_test.go
  --include-vendor      Process vendor/ directories (skipped by default)

Examples:
  rm-comments src/main.go                      # Auto-detect Go, dry-run
  rm-comments --write src/                     # Auto-detect, write changes
  rm-comments --lang python --write script.txt # Force Python mode
  rm-comments --quiet --write project/         # Quiet mode
  rm-comments --remove-directives main.go      # Strip everything (Go)
```

### File Processing Flow

```
1. User runs: rm-comments [options] <path>
2. Wrapper parses common flags
3. Language detection:
   - If --lang specified: Use that language
   - Else if path is file: Detect from extension
   - Else if path is directory: Process all supported files
4. For each matching file:
   a. Read source code
   b. Pass to appropriate backend
   c. Backend parses and strips comments
   d. Compare output with original
   e. If --write: Write back (preserve permissions)
   f. Log: "updated" / "would update" / "no change"
5. Summary: "Scanned: X, Changed: Y, Mode: write|dry-run"
```

## Risks / Trade-offs

### Risk: Bash Wrapper Complexity
**Impact**: Medium (could become hard to maintain)
**Mitigation**:
- Keep wrapper simple: just routing logic
- All complex logic stays in language backends
- Clear comments and structure
- Limit to ~100 lines of bash

### Risk: Build Complexity with Multiple Languages
**Impact**: Medium (longer build times, dependency management)
**Mitigation**:
- Use standard Nix builders where possible
- Clear separation of build phases
- Comprehensive documentation for hash updates
- CI validates builds on every change

### Risk: Language Detection Failures
**Impact**: Low (clear error messages guide users)
**Mitigation**:
- Explicit error when detection fails
- Suggest using --lang flag in error message
- Document supported extensions clearly

### Risk: Backend Synchronization
**Impact**: Low (backends might have inconsistent behavior)
**Mitigation**:
- Use proven implementations from issue #172
- Document behavior differences where they exist
- Consistent dry-run/write behavior across all

## Migration Plan

### Installation
1. Add new directory `modules/programs/rm-comments/` with all source files
2. Add to `modules/features/engineer.nix`: `rm-comments.enable = true`
3. Rebuild system configuration: `darwin-rebuild switch` or `nixos-rebuild build`

### No Breaking Changes
- Purely additive feature
- No changes to existing tools or workflows
- Optional enablement via engineer feature or explicit enable

### Rollback
If issues arise:
1. Set `myconfig.programs.rm-comments.enable = false` in engineer.nix
2. Rebuild system configuration
3. Program removed from system packages

## Testing Strategy

### Backend Testing (Development Phase)

**Go Backend**:
```bash
cd modules/programs/rm-comments/go
go build -o rm-comments-go-backend main.go
./rm-comments-go-backend testdata/sample.go  # dry-run
./rm-comments-go-backend --write testdata/
```

**Python Backend**:
```bash
cd modules/programs/rm-comments/python
python3 main.py testdata/sample.py
```

**Rust Backend**:
```bash
cd modules/programs/rm-comments/rust
cargo build
./target/debug/rm-comments-rs-backend testdata/sample.rs
```

**TypeScript Backend**:
```bash
cd modules/programs/rm-comments/tsx
npm install
npx tsx remove-comments.ts testdata/sample.tsx
```

### Integration Testing (Nix Build)

```bash
cd modules/programs/rm-comments
nix build  # Build complete derivation

# Test the wrapper
./result/bin/rm-comments --help
./result/bin/rm-comments testdata/sample.go
./result/bin/rm-comments --lang python testdata/
./result/bin/rm-comments --write --quiet testdata/
```

### System Integration

```bash
# Validate flake
nix flake check

# Build system configuration (don't switch)
darwin-rebuild build --flake . --show-trace  # macOS
nixos-rebuild build --flake . --show-trace   # NixOS

# After successful build, test the installed command
rm-comments --help
rm-comments /path/to/test/files
```

### Manual Test Matrix

| Test Case | Command | Expected Result |
|-----------|---------|----------------|
| Auto-detect Go | `rm-comments main.go` | Processes as Go |
| Auto-detect Python | `rm-comments script.py` | Processes as Python |
| Explicit language | `rm-comments --lang rust file.txt` | Forces Rust mode |
| Dry-run default | `rm-comments file.go` | Shows changes, doesn't write |
| Write mode | `rm-comments --write file.go` | Writes changes |
| Directory processing | `rm-comments --write src/` | Processes all files recursively |
| Quiet mode | `rm-comments --quiet --write src/` | Only shows summary |
| Go directives preserved | `rm-comments --write main.go` | Keeps //go:build |
| Go directives removed | `rm-comments --remove-directives --write main.go` | Removes all |

## Open Questions

1. **Should we support stdin/stdout for pipeline usage?**
   - E.g., `cat file.go | rm-comments --lang go`
   - **Decision**: Defer to implementation phase. Not essential for initial version.

2. **Should we provide a unified wrapper command for easier scripting?**
   - E.g., `rm-comments --all src/` to process all languages in mixed directory
   - **Decision**: Auto-detection already handles this. Not needed.

3. **Should we add more languages later?**
   - C/C++, Java, JavaScript, etc.
   - **Decision**: Yes, architecture supports it. Add based on user demand.

4. **Should directory processing be parallel?**
   - Process multiple files concurrently
   - **Decision**: Defer. Sequential is simpler and fast enough for typical use.

5. **Should we expose backends as separate commands too?**
   - E.g., make `rm-comments-go-backend` available as `rm-comments-go`
   - **Decision**: No. Unified interface is the goal. Backends are internal implementation details.
