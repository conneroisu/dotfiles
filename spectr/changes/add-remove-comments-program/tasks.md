## 1. Create Program Directory Structure

- [ ] 1.1 Create `modules/programs/remove-comments/` directory
- [ ] 1.2 Create `default.nix` with Go package derivation
- [ ] 1.3 Create `main.go` with all Go comment stripping logic
- [ ] 1.4 Create auxiliary Go helper functions (directive filtering, normalization)

## 2. Implement Go Comment Stripping

- [ ] 2.1 Implement `stripCommentsInFile()` using Go AST parsing
- [ ] 2.2 Implement `filterDirectiveCommentGroups()` to preserve build directives
- [ ] 2.3 Implement regex patterns for `//go:*`, `//+build`, `#cgo`, `#include`
- [ ] 2.4 Add support for all flag types: `-root`, `-write`, `-remove-directives`, `-skip-tests`, `-include-vendor`, `-quiet`
- [ ] 2.5 Implement recursive `filepath.WalkDir()` scanning

## 3. Create Multi-Language Support Infrastructure

- [ ] 3.1 Create wrapper script `remove-comments` that dispatches to language-specific implementations
- [ ] 3.2 Implement Python version (tokenize-based) in `remove_comments.py`
- [ ] 3.3 Implement Rust version (state machine) in `remove_comments.rs` or as pre-built binary
- [ ] 3.4 Implement TypeScript/TSX version in `remove_comments.ts`

## 4. Build and Package Integration

- [ ] 4.1 Ensure `default.nix` properly builds Go binary
- [ ] 4.2 Create wrapper scripts for Python, Rust, TypeScript implementations
- [ ] 4.3 Package all implementations into single nixpkgs-compatible derivation
- [ ] 4.4 Verify cross-platform (nixos, darwin, home-manager) compatibility

## 5. Module Discovery and Integration

- [ ] 5.1 Create `modules/config/` entry or update auto-discovery if needed
- [ ] 5.2 Ensure `remove-comments` module follows Denix patterns
- [ ] 5.3 Verify module is discovered by flake auto-discovery

## 6. Testing and Validation

- [ ] 6.1 Test Go implementation on .go files with build directives
- [ ] 6.2 Test Python implementation on .py files with shebangs
- [ ] 6.3 Test Rust implementation on .rs files with raw strings
- [ ] 6.4 Test TypeScript implementation on .tsx files with JSX comments
- [ ] 6.5 Verify dry-run mode doesn't modify files
- [ ] 6.6 Verify `-write` flag correctly persists changes
- [ ] 6.7 Test directory scanning with skip patterns
- [ ] 6.8 Test with vendor/ and .direnv exclusions
- [ ] 6.9 Verify quiet mode suppresses per-file logs

## 7. Documentation and Cleanup

- [ ] 7.1 Add inline documentation to main implementations
- [ ] 7.2 Test `remove-comments --help` output
- [ ] 7.3 Verify no breaking changes to existing modules/features
- [ ] 7.4 Run `nix develop -c lint` to check for style issues
- [ ] 7.5 Run `nix fmt` to format code
