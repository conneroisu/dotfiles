## Why

Comments can add significant overhead to code size and are often unnecessary in production or distribution contexts. A robust `remove-comments` program provides a reusable utility for stripping comments from source code across multiple languages while preserving build-critical directives (like Go build tags, Rust attributes, and Python shebangs).

## What Changes

- Add new custom program module: `modules/programs/remove-comments/`
  - Go implementation with comprehensive comment stripping
  - Support for build directives and cgo preambles
  - Python, Rust, and TypeScript/TSX support through separate implementations
  - Cross-platform deployment (NixOS, Darwin, Home Manager)
  - Dry-run mode by default, with write mode via flag
  - Recursive directory scanning with customizable filters

## Impact

- Affected specs: `custom-programs` (new capability)
- Affected code: `modules/programs/remove-comments/` (new), `flake.nix` (auto-discovery)
- No breaking changes; purely additive
- Available as a system package after flake update
