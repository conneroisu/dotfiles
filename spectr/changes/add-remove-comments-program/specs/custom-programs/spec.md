## ADDED Requirements

### Requirement: Remove Comments Program
The system SHALL provide a `remove-comments` utility that strips comments and docstrings from source code across multiple languages (Go, Python, Rust, TypeScript/TSX) while preserving build-critical directives and operating in dry-run mode by default.

#### Scenario: Go file comment stripping
- **WHEN** user runs `remove-comments` on a Go source file with ordinary comments
- **THEN** comments are removed but build directives (`//go:build`, `//go:generate`, etc.) and cgo preambles (`#cgo`, `#include`) are preserved

#### Scenario: Python docstring removal
- **WHEN** user runs `remove-comments` on a Python file with docstrings and comments
- **THEN** docstrings and comments are removed but shebangs (`#!/usr/bin/env python3`) are preserved

#### Scenario: Rust comment stripping
- **WHEN** user runs `remove-comments` on Rust source with block and line comments
- **THEN** comments are removed while preserving raw string literals and byte strings intact

#### Scenario: TypeScript/TSX comment removal
- **WHEN** user runs `remove-comments` on a `.tsx` file with JS/TS comments and JSX comment expressions
- **THEN** all comment styles are removed including JSX comment blocks (`{/* ... */}`) without leaving artifacts

#### Scenario: Dry-run mode (default behavior)
- **WHEN** user runs `remove-comments [path]` without the `-write` flag
- **THEN** the program outputs what would be changed but does not modify files

#### Scenario: Write mode activation
- **WHEN** user runs `remove-comments -write [path]`
- **THEN** the program writes changes back to files with original permissions preserved

#### Scenario: Recursive directory scanning
- **WHEN** user runs `remove-comments` on a directory
- **THEN** the program recursively finds and processes all supported language files while skipping `.direnv` and optionally `vendor/` directories

#### Scenario: Build directive preservation (optional)
- **WHEN** user runs `remove-comments -remove-directives [path]` on Go files
- **THEN** build directives, cgo preambles, and go:* directives are also removed (dangerous; may break builds)

#### Scenario: Test file filtering (optional)
- **WHEN** user runs `remove-comments -skip-tests [path]`
- **THEN** files matching `*_test.go`, `*_test.py`, `*_test.rs`, `*.test.tsx` are skipped

#### Scenario: Quiet mode
- **WHEN** user runs `remove-comments -quiet [path]`
- **THEN** per-file logging is suppressed; only errors are printed

### Requirement: Cross-Platform Availability
The system SHALL provide the `remove-comments` program as a deployable system package on NixOS, macOS (darwin), and Home Manager environments through automatic module discovery.

#### Scenario: NixOS availability
- **WHEN** `remove-comments` module is discovered by Denix
- **THEN** the program is available in `environment.systemPackages` on NixOS hosts

#### Scenario: Darwin availability
- **WHEN** `remove-comments` module is discovered by Denix
- **THEN** the program is available in `environment.systemPackages` on macOS hosts via nix-darwin

#### Scenario: Home Manager availability
- **WHEN** `remove-comments` module is discovered by Denix
- **THEN** the program is available in `home.packages` on Home Manager installations

### Requirement: Default Behavior Safety
The system SHALL implement sensible defaults that prioritize safety and non-destructive operation.

#### Scenario: Dry-run prevents accidental modification
- **WHEN** user runs `remove-comments [path]`
- **THEN** the program operates in dry-run mode by default, requiring explicit `-write` flag to modify files

#### Scenario: Directive preservation protects builds
- **WHEN** user runs standard `remove-comments -write [path]` on Go files
- **THEN** build directives and cgo preambles remain untouched unless `-remove-directives` is explicitly provided
