# Implementation Tasks: rm-comments Unified Comment Removal Tool

## 1. Setup and Scaffolding
- [ ] 1.1 Create `modules/programs/rm-comments/` directory structure
- [ ] 1.2 Create subdirectories: `go/`, `python/`, `rust/`, `tsx/`
- [ ] 1.3 Set up `default.nix` skeleton with delib.module pattern

## 2. Bash Wrapper Implementation
- [ ] 2.1 Create `rm-comments.sh` bash wrapper script
- [ ] 2.2 Implement argument parsing for common flags (--lang, --write, --quiet)
- [ ] 2.3 Implement language detection from file extensions
- [ ] 2.4 Implement routing logic to language-specific backends
- [ ] 2.5 Add help/usage information display
- [ ] 2.6 Implement error handling for invalid languages and missing paths
- [ ] 2.7 Add directory processing logic for multi-language support
- [ ] 2.8 Test wrapper with all language backends

## 3. Go Backend Implementation
- [ ] 3.1 Copy Go implementation from GitHub issue #172 to `go/main.go`
- [ ] 3.2 Create `go/go.mod` with necessary dependencies
- [ ] 3.3 Verify flags: --write, --remove-directives, --skip-tests, --include-vendor, --quiet
- [ ] 3.4 Test Go backend standalone: `cd go && go build && ./rm-comments-go-backend testdata/`
- [ ] 3.5 Verify compiler directives are preserved by default
- [ ] 3.6 Verify --remove-directives removes all comments including directives
- [ ] 3.7 Test recursive directory processing with vendor/ and test file skipping

## 4. Python Backend Implementation
- [ ] 4.1 Copy Python implementation from GitHub issue #172 to `python/main.py`
- [ ] 4.2 Ensure shebang preservation logic is correct
- [ ] 4.3 Test Python backend standalone: `python3 python/main.py testdata/`
- [ ] 4.4 Verify comments and docstrings are removed
- [ ] 4.5 Verify shebang lines are preserved
- [ ] 4.6 Test recursive directory processing

## 5. Rust Backend Implementation
- [ ] 5.1 Copy Rust implementation from GitHub issue #172 to `rust/src/main.rs`
- [ ] 5.2 Create `rust/Cargo.toml` with package metadata
- [ ] 5.3 Test Rust backend standalone: `cd rust && cargo build && ./target/debug/rm-comments-rs-backend testdata/`
- [ ] 5.4 Verify nested block comments are handled correctly
- [ ] 5.5 Verify raw string literals are preserved
- [ ] 5.6 Test recursive directory processing with .direnv skipping

## 6. TypeScript/TSX Backend Implementation
- [ ] 6.1 Copy TypeScript implementation from GitHub issue #172 to `tsx/remove-comments.ts`
- [ ] 6.2 Create `tsx/package.json` with typescript dependency
- [ ] 6.3 Create `tsx/tsconfig.json` for TypeScript compiler configuration
- [ ] 6.4 Test TypeScript backend standalone: `cd tsx && npm install && npx tsx remove-comments.ts testdata/`
- [ ] 6.5 Verify TypeScript comments are removed
- [ ] 6.6 Verify JSX comment expressions `{/* ... */}` are removed without leaving empty braces
- [ ] 6.7 Test recursive directory processing with node_modules skipping

## 7. Nix Derivation Implementation
- [ ] 7.1 Write `default.nix` using `pkgs.stdenv.mkDerivation`
- [ ] 7.2 Add buildInputs: go, python3, rustc, cargo, nodejs, typescript
- [ ] 7.3 Implement buildPhase:
  - [ ] 7.3.1 Build Go backend: `cd go && go build -o ../rm-comments-go-backend`
  - [ ] 7.3.2 Build Rust backend: `cd rust && cargo build --release`
  - [ ] 7.3.3 Build TypeScript backend: `cd tsx && npm install && npm run build`
- [ ] 7.4 Implement installPhase:
  - [ ] 7.4.1 Create $out/bin and $out/libexec/rm-comments directories
  - [ ] 7.4.2 Copy all backends to $out/libexec/rm-comments/
  - [ ] 7.4.3 Copy rm-comments.sh to $out/bin/rm-comments
  - [ ] 7.4.4 Set executable permissions on wrapper
- [ ] 7.5 Update wrapper to find backends in $out/libexec/rm-comments/
- [ ] 7.6 Add delib.module wrapper with singleEnableOption pattern
- [ ] 7.7 Add nixos.ifEnabled and darwin.ifEnabled sections

## 8. Integration with Engineer Feature
- [ ] 8.1 Add `rm-comments.enable = true` to `modules/features/engineer.nix`
- [ ] 8.2 Place after existing program enables for consistency

## 9. Testing
- [ ] 9.1 Create testdata directory with sample files for each language
- [ ] 9.2 Test Nix build: `cd modules/programs/rm-comments && nix build`
- [ ] 9.3 Test wrapper help: `./result/bin/rm-comments --help`
- [ ] 9.4 Test language auto-detection for each file type
- [ ] 9.5 Test explicit --lang flag with each language
- [ ] 9.6 Test dry-run mode (default behavior)
- [ ] 9.7 Test --write mode on testdata
- [ ] 9.8 Test --quiet mode
- [ ] 9.9 Test directory processing with mixed languages
- [ ] 9.10 Test Go-specific flags (--remove-directives, --skip-tests, --include-vendor)
- [ ] 9.11 Test error handling (invalid path, invalid language, parse errors)
- [ ] 9.12 Verify file permissions are preserved after write

## 10. System Integration Testing
- [ ] 10.1 Run `nix develop -c lint` to validate Nix code
- [ ] 10.2 Run `nix fmt` to format code
- [ ] 10.3 Run `nix flake check` to validate flake outputs
- [ ] 10.4 Build system configuration without switching:
  - [ ] 10.4.1 macOS: `darwin-rebuild build --flake . --show-trace`
  - [ ] 10.4.2 NixOS: `nixos-rebuild build --flake . --show-trace`
- [ ] 10.5 Switch to new configuration:
  - [ ] 10.5.1 macOS: `darwin-rebuild switch --flake . --show-trace`
  - [ ] 10.5.2 NixOS: `sudo nixos-rebuild switch --flake . --show-trace`
- [ ] 10.6 Verify `rm-comments` command is in PATH
- [ ] 10.7 Run manual smoke tests on real codebases

## 11. Documentation and Cleanup
- [ ] 11.1 Add module docstring to `default.nix` documenting the program
- [ ] 11.2 Add inline comments to bash wrapper for clarity
- [ ] 11.3 Verify all backends have appropriate error messages
- [ ] 11.4 Update CLAUDE.md if necessary (shouldn't be needed, follows existing patterns)
- [ ] 11.5 Remove testdata directory or add to .gitignore if keeping

## 12. Validation and Completion
- [ ] 12.1 Re-run all tests from section 9
- [ ] 12.2 Verify summary output is consistent across all language backends
- [ ] 12.3 Confirm cross-platform functionality (test on both NixOS and Darwin if possible)
- [ ] 12.4 Verify the program is enabled via engineer feature automatically
- [ ] 12.5 Final `nix flake check` passes without errors
- [ ] 12.6 Mark all tasks complete in this file

## Implementation Notes

### Build Order
1. Implement and test each backend individually first (sections 3-6)
2. Create testdata files early to use for backend testing
3. Implement bash wrapper after backends are working (section 2)
4. Integrate into Nix derivation last (section 7)
5. System integration and testing (sections 8-10)

### Testing Strategy
- Test each backend standalone before Nix integration
- Use real-world code samples from each language for testdata
- Verify edge cases: nested comments (Rust), JSX expressions (TSX), directives (Go), docstrings (Python)
- Always test dry-run before testing write mode to avoid data loss

### Common Issues to Watch For
- **Nix build caching**: Clear build cache if changes aren't reflected: `nix-collect-garbage -d`
- **VendorHash for Go**: May need to update `vendorHash` if go.mod dependencies change
- **Cargo.lock for Rust**: Commit Cargo.lock to ensure reproducible builds
- **npm package-lock.json**: May be needed for TypeScript reproducibility
- **Path resolution in wrapper**: Ensure wrapper correctly finds backends in $out/libexec
- **Executable permissions**: Verify all binaries and wrapper have +x after installation

### Manual Test Cases Checklist
```bash
# Go tests
rm-comments testdata/sample.go                    # Dry-run
rm-comments --write testdata/sample.go            # Write mode
rm-comments --remove-directives testdata/main.go  # Strip directives

# Python tests
rm-comments testdata/script.py                    # With shebang
rm-comments --write testdata/module.py            # With docstrings

# Rust tests
rm-comments testdata/lib.rs                       # Nested comments
rm-comments --write testdata/main.rs              # Raw strings

# TypeScript tests
rm-comments testdata/component.tsx                # JSX comments
rm-comments --write testdata/app.ts               # Regular comments

# Mixed directory
rm-comments --write testdata/                     # All languages

# Edge cases
rm-comments --lang go testdata/no-extension       # Force language
rm-comments testdata/invalid.xyz                  # Detection failure
rm-comments nonexistent/path                      # Invalid path
```
