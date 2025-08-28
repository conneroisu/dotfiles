/**
# Rust Development Shell Template

## Description
Comprehensive Rust development environment with modern tooling and optimized
build configuration. Features the latest stable Rust toolchain, advanced
caching with crane, and complete development workflow support for building
high-performance Rust applications.

## Platform Support
- ✅ x86_64-linux
- ✅ aarch64-linux (ARM64 Linux)
- ✅ x86_64-darwin (Intel macOS)
- ✅ aarch64-darwin (Apple Silicon macOS)

## What This Provides
- **Rust Toolchain**: Latest stable Rust with rustup integration
- **Build Tools**: Crane for optimized Nix builds with incremental compilation
- **Development Tools**: rust-analyzer, clippy, rustfmt, cargo-watch
- **Testing**: cargo-nextest for faster test execution
- **Documentation**: Built-in doc generation and viewing
- **Code Quality**: clippy linting and rustfmt formatting

## Key Features
- **Rust Overlay**: Access to multiple Rust versions and components
- **Incremental Builds**: Crane-based caching for faster rebuilds
- **IDE Integration**: rust-analyzer for rich editor support
- **Cross-compilation**: Support for multiple target architectures
- **Modern Formatting**: rustfmt with treefmt integration

## Usage
```bash
# Create new project from template
nix flake init -t github:conneroisu/dotfiles#rust-shell

# Enter development shell
nix develop

# Build with caching
nix build

# Run tests
cargo test

# Format code
nix fmt
```

## Development Workflow
- Use cargo-watch for automatic recompilation
- clippy provides comprehensive linting
- rust-analyzer enables rich IDE features
- crane optimizes build times with intelligent caching
*/
{
  description = "A development shell for rust";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    crane.url = "github:ipetkov/crane";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    rust-overlay,
    crane,
    treefmt-nix,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [rust-overlay.overlays.default];
      };
      # Optional: Initialize crane for building packages
      # craneLib = (crane.mkLib pkgs).overrideToolchain (p: p.rust-bin.stable.latest.default);
      # Optional: Example crane package build (uncomment to use)
      # my-crate = craneLib.buildPackage {
      #   src = craneLib.cleanCargoSource ./.;
      #   strictDeps = true;
      # };
    in {
      # Optional: Define packages if using crane to build (uncomment to use)
      # packages = forAllSystems (system: let
      #   pkgs = import nixpkgs {
      #     inherit system;
      #     overlays = [rust-overlay.overlays.default];
      #   };
      #   craneLib = (crane.mkLib pkgs).overrideToolchain (p: p.rust-bin.stable.latest.default);
      # in {
      #   default = craneLib.buildPackage {
      #     src = craneLib.cleanCargoSource ./.;
      #     strictDeps = true;
      #   };
      # });

      rooted = exec:
        builtins.concatStringsSep "\n"
        [
          ''REPO_ROOT="$(git rev-parse --show-toplevel)"''
          exec
        ];

      scripts = {
        dx = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/flake.nix'';
          description = "Edit flake.nix";
        };
        rx = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/Cargo.toml'';
          description = "Edit Cargo.toml";
        };
      };

      scriptPackages =
        pkgs.lib.mapAttrs
        (
          name: script:
            pkgs.writeShellApplication {
              inherit name;
              text = script.exec;
              runtimeInputs = script.deps or [];
            }
        )
        scripts;

      devShells.default = pkgs.mkShell {
        name = "dev";
        # Available packages on https://search.nixos.org/packages
        buildInputs = with pkgs; [
          alejandra # Nix
          nixd
          statix
          deadnix
          just
          rust-bin.stable.latest.default
        ]
        ++ builtins.attrValues scriptPackages;
        shellHook = ''
          echo "Welcome to the rust devshell!"
        '';
      };

      formatter = let
        treefmtModule = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true; # Nix formatter
            rustfmt.enable = true; # Rust formatter
          };
        };
      in
        treefmt-nix.lib.mkWrapper pkgs treefmtModule;
    });
}
