/**
# TypeScript Development Shell Template

## Description
Comprehensive TypeScript development environment with modern tooling for building
high-quality TypeScript applications. Features multiple linters, formatters,
language servers, and development tools for productive TypeScript development.

## Platform Support
- ✅ x86_64-linux
- ✅ aarch64-linux (ARM64 Linux)
- ✅ x86_64-darwin (Intel macOS)
- ✅ aarch64-darwin (Apple Silicon macOS)

## What This Provides
- **TypeScript Toolchain**: Latest TypeScript compiler and runtime
- **Multiple Linters**: ESLint, oxlint, and Biome for comprehensive code analysis
- **Language Servers**: TypeScript LSP, Tailwind CSS LSP for rich IDE integration
- **Package Managers**: npm, yarn, pnpm, and bun for flexible dependency management
- **Development Tools**: Prettier, tsx for TypeScript execution, and more
- **Testing**: Vitest for modern TypeScript testing

## Key Features
- **Multi-linter Setup**: Choose between ESLint, oxlint, or Biome based on project needs
- **IDE Integration**: Rich language server support for editors
- **Modern Runtime**: bun and tsx for fast TypeScript execution
- **CSS Framework Support**: Tailwind CSS language server included
- **Formatting**: Prettier and Biome for consistent code style

## Usage
```bash
# Create new project from template
nix flake init -t github:conneroisu/dotfiles#typescript-shell

# Enter development shell
nix develop

# Initialize TypeScript project
tsc --init

# Run TypeScript with tsx
tsx src/index.ts

# Format code
nix fmt
```

## Development Workflow
- Use tsx for rapid TypeScript development
- Multiple linting options for different project requirements
- Rich IDE support with language servers
- Modern package management with multiple options
*/
{
  description = "A development shell for TypeScript";
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
        config.allowUnfree = true;
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
          deps = [pkgs.git];
        };
        tx = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/tsconfig.json'';
          description = "Edit tsconfig.json";
        };
        px = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/package.json'';
          description = "Edit package.json";
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
    in {
      devShells.default = pkgs.mkShell {
        name = "typescript-dev";

        # Available packages on https://search.nixos.org/packages
        packages = with pkgs;
          [
            # Nix tooling
            alejandra
            nixd
            statix
            deadnix

            # TypeScript core
            typescript
            nodejs
            tsx # Fast TypeScript execution

            # Package managers
            bun

            # Linters and formatters
            eslint
            oxlint
            biome
            nodePackages.prettier

            # Language servers
            typescript-language-server
            tailwindcss-language-server
            vscode-langservers-extracted # HTML, CSS, JSON, ESLint LSPs
            yaml-language-server

            # CSS and styling
            tailwindcss
            nodePackages.autoprefixer

            # Utility tools
            jq # JSON processing
            nodePackages.concurrently # Run multiple commands
            nodePackages.nodemon # File watching
          ]
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
          echo "Available commands:"
          ${pkgs.lib.concatStringsSep "\n" (
            pkgs.lib.mapAttrsToList (name: script: ''echo "  ${name} - ${script.description}"'') scripts
          )}
        '';
      };

      packages = {
        # Example TypeScript package build (uncomment and customize)
        # default = pkgs.buildNpmPackage {
        #   pname = "my-typescript-project";
        #   version = "0.1.0";
        #   src = ./.;
        #   npmDepsHash = ""; # Run nix build to get the correct hash
        #   buildPhase = ''
        #     npm run build
        #   '';
        #   installPhase = ''
        #     mkdir -p $out
        #     cp -r dist/* $out/
        #   '';
        #   meta = with pkgs.lib; {
        #     description = "My TypeScript project";
        #     homepage = "https://github.com/user/my-typescript-project";
        #     license = licenses.mit;
        #     maintainers = with maintainers; [ ];
        #   };
        # };
      };

      formatter = let
        treefmtModule = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true; # Nix formatter
            prettier.enable = true; # JavaScript/TypeScript formatter
            biome.enable = true; # Alternative all-in-one formatter
          };
          settings = {
            formatter = {
              prettier = {
                options = ["--tab-width" "2" "--print-width" "100"];
                includes = ["*.ts" "*.tsx" "*.js" "*.jsx" "*.json" "*.md" "*.css" "*.html"];
              };
            };
          };
        };
      in
        treefmt-nix.lib.mkWrapper pkgs treefmtModule;
    });
}
