/**
# Development Shell Template

## Description
Generic development environment template with essential tools and formatting setup.
Provides a foundation for creating project-specific development environments with
Nix flakes. Includes treefmt for code formatting and a basic shell structure.

## Platform Support
- ✅ x86_64-linux
- ✅ aarch64-linux (ARM64 Linux)
- ✅ x86_64-darwin (Intel macOS)
- ✅ aarch64-darwin (Apple Silicon macOS)

## What This Provides
- **Development Shell**: Basic shell environment with just (task runner)
- **Code Formatting**: treefmt with Alejandra for Nix code formatting
- **Multi-platform**: Support for all major architectures
- **Flake Structure**: Modern flake.nix template using flake-parts

## Usage
```bash
# Create new project from template
nix flake init -t github:conneroisu/dotfiles#devshell

# Enter development shell
nix develop

# Format code
nix fmt
```

## Customization
- Add packages to buildInputs array
- Modify shellHook for custom initialization
- Add language-specific formatters to treefmtModule
- Extend with additional development tools as needed
*/
{
  description = "A development shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs @ {nixpkgs, treefmt-nix, ...}: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        name = "dev";

        # Available packages on https://search.nixos.org/packages
        buildInputs = with pkgs; [
          just
        ];

        shellHook = ''
          echo "Welcome to the devshell!"
        '';
      };
    });

    formatter = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtModule = {
        projectRootFile = "flake.nix";
        programs = {
          alejandra.enable = true; # Nix formatter
        };
      };
    in
      treefmt-nix.lib.mkWrapper pkgs treefmtModule);
  };
}
