/**
# Go + Templ Development Shell Template

## Description
Development environment for Go applications using the Templ template engine.
Provides Go toolchain with Templ-specific tools for building modern web
applications with type-safe HTML templating in Go.

## Platform Support
- ✅ x86_64-linux
- ✅ aarch64-linux (ARM64 Linux)
- ✅ x86_64-darwin (Intel macOS)
- ✅ aarch64-darwin (Apple Silicon macOS)

## What This Provides
- **Go Toolchain**: Go 1.24 compiler and runtime
- **Templ Tools**: Templ compiler for Go HTML templates
- **Development Tools**: air (live reload), gopls (language server)
- **Code Quality**: golangci-lint, revive, gofmt formatting
- **Testing**: Go testing tools and gotests for test generation
- **Documentation**: gomarkdoc for generating documentation

## Usage
```bash
# Create new project from template
nix flake init -t github:conneroisu/dotfiles#templ-shell

# Enter development shell
nix develop

# Generate templ files
templ generate

# Start live reload development
air

# Format code
nix fmt
```

## Development Workflow
- Use templ for type-safe HTML templates
- air provides automatic recompilation
- Rich IDE integration with gopls
- Comprehensive linting with golangci-lint
*/
{
  description = "A development shell for go + templ";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    nixpkgs,
    flake-utils,
    treefmt-nix,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
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
        gx = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/go.mod'';
          description = "Edit go.mod";
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

      buildWithSpecificGo = pkg: pkg.override {buildGoModule = pkgs.buildGo124Module;};
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

            go_1_24 # Go Tools
            air
            gopls
            golangci-lint
            (buildWithSpecificGo revive)
            (buildWithSpecificGo templ)
            (buildWithSpecificGo golines)
            (buildWithSpecificGo golangci-lint-langserver)
            (buildWithSpecificGo gomarkdoc)
            (buildWithSpecificGo gotests)
            (buildWithSpecificGo gotools)
            (buildWithSpecificGo reftools)
            pprof
            graphviz
            goreleaser
            cobra-cli
          ]
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
          echo "Welcome to the go-templ devshell!"
        '';
      };

      packages = {
        # default = pkgs.buildGoModule {
        #   pname = "my-go-project";
        #   version = "0.0.1";
        #   src = ./.;
        #   vendorHash = "";
        #   doCheck = false;
        #   meta = with pkgs.lib; {
        #     description = "My Go project";
        #     homepage = "https://github.com/conneroisu/my-go-project";
        #     license = licenses.asl20;
        #     maintainers = with maintainers; [connerohnesorge];
        #   };
        # };
      };

      formatter = let
        treefmtModule = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true; # Nix formatter
          };
        };
      in
        treefmt-nix.lib.mkWrapper pkgs treefmtModule;
    });
}
