/**
# Zig Development Shell Template

## Description
Complete Zig development environment with modern tooling for building, testing,
and maintaining Zig applications. Includes the Zig compiler, ZLS language server,
formatting utilities, and development scripts for productive Zig development.

## Platform Support
- ✅ x86_64-linux
- ✅ aarch64-linux (ARM64 Linux)
- ✅ x86_64-darwin (Intel macOS)
- ✅ aarch64-darwin (Apple Silicon macOS)

## What This Provides
- **Zig Toolchain**: Latest Zig master compiler and runtime
- **Language Server**: ZLS for rich IDE integration
- **Development Tools**: Build automation and project management
- **Code Quality**: Formatting with zig fmt integration
- **Documentation**: Built-in documentation generation
- **Nix Tools**: Formatting and linting for Nix files

## Usage
```bash
# Create new project from template
nix flake init -t github:conneroisu/dotfiles#zig-shell

# Enter development shell
nix develop

# Build project
zig build

# Run tests
zig test src/main.zig

# Format code
nix fmt
```

## Development Workflow
- Use `zig build` for compilation and linking
- ZLS provides comprehensive IDE integration
- Built-in formatter ensures consistent code style
- All tools configured for optimal Zig development experience
*/
{
  description = "A development shell for zig";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    zls = {
      url = "github:zigtools/zls";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.zig-overlay.follows = "zig-overlay";
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    treefmt-nix,
    zig-overlay,
    zls,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          zig-overlay.overlays.default
          (final: prev: {
            # Add your overlays here
            # Example:
            # my-overlay = final: prev: {
            #   my-package = prev.callPackage ./my-package { };
            # };
          })
        ];
      };

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
        zx = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/build.zig'';
          description = "Edit build.zig";
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

      treefmtModule = {
        projectRootFile = "flake.nix";
        programs = {
          alejandra.enable = true; # Nix formatter
          zig.enable = pkgs.stdenv.isLinux; # Zig formatter (Linux only, broken on macOS)
        };
      };
    in {
      devShells.default = pkgs.mkShell {
        name = "dev";

        # Available packages on https://search.nixos.org/packages
        packages = with pkgs;
          [
            alejandra # Nix
            nixd
            statix
            deadnix

            zigpkgs.master # Zig Tools
            lldb # Debugger
            gdb # Alternative debugger
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            # Linux-only debugging tools
            valgrind # Memory debugging (Linux only)
          ]
          ++ [
            zls.packages.${system}.zls # Zig Language Server
          ]
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
          echo "Welcome to the Zig development shell!"
          echo "Available commands:"
          echo "  dx - Edit flake.nix"
          echo "  zx - Edit build.zig"
          echo "  zig build - Build the project"
          echo "  zig test - Run tests"
          echo "  nix fmt - Format code"
        '';
      };

      packages = {
        default = pkgs.stdenv.mkDerivation {
          pname = "my-zig-project";
          version = "0.0.1";
          src = self;
          nativeBuildInputs = [ pkgs.zigpkgs.master ];
          buildPhase = ''
            zig build
          '';
          installPhase = ''
            mkdir -p $out/bin
            # Copy built executables to $out/bin
            # Adjust this based on your project structure
            if [ -d "zig-out/bin" ]; then
              cp -r zig-out/bin/* $out/bin/
            fi
          '';
          meta = with pkgs.lib; {
            description = "My Zig project";
            homepage = "https://github.com/conneroisu/my-zig-project";
            license = licenses.mit;
            maintainers = with maintainers; [connerohnesorge];
          };
        };
      };

      formatter = treefmt-nix.lib.mkWrapper pkgs treefmtModule;
    });
}
