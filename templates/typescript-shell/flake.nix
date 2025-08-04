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
        init-ts = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ ! -f tsconfig.json ]; then
              tsc --init --target ES2022 --module ESNext --moduleResolution bundler --allowImportingTsExtensions --noEmit --strict
              echo "TypeScript project initialized!"
            else
              echo "tsconfig.json already exists"
            fi
          '';
          deps = with pkgs; [typescript];
          description = "Initialize TypeScript project";
        };
        init-package = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ ! -f package.json ]; then
              npm init -y
              echo "package.json created!"
            else
              echo "package.json already exists"
            fi
          '';
          deps = with pkgs; [nodejs];
          description = "Initialize npm package.json";
        };
        lint-eslint = {
          exec = rooted ''
            cd "$REPO_ROOT"
            eslint . --ext .ts,.tsx,.js,.jsx --fix
          '';
          deps = with pkgs; [eslint];
          description = "Lint with ESLint";
        };
        lint-oxlint = {
          exec = rooted ''
            cd "$REPO_ROOT"
            oxlint --fix
          '';
          deps = with pkgs; [oxlint];
          description = "Lint with oxlint";
        };
        lint-biome = {
          exec = rooted ''
            cd "$REPO_ROOT"
            biome lint --apply .
          '';
          deps = with pkgs; [biome];
          description = "Lint with Biome";
        };
        format-prettier = {
          exec = rooted ''
            cd "$REPO_ROOT"
            prettier --write "**/*.{ts,tsx,js,jsx,json,md,css,html}"
          '';
          deps = with pkgs; [nodePackages.prettier];
          description = "Format with Prettier";
        };
        format-biome = {
          exec = rooted ''
            cd "$REPO_ROOT"
            biome format --write .
          '';
          deps = with pkgs; [biome];
          description = "Format with Biome";
        };
        typecheck = {
          exec = rooted ''
            cd "$REPO_ROOT"
            tsc --noEmit
          '';
          deps = with pkgs; [typescript];
          description = "Run TypeScript type checking";
        };
        dev = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -f "src/index.ts" ]; then
              tsx watch src/index.ts
            elif [ -f "index.ts" ]; then
              tsx watch index.ts
            else
              echo "No TypeScript entry file found (src/index.ts or index.ts)"
              echo "Create one to start development"
            fi
          '';
          deps = with pkgs; [tsx];
          description = "Start development server with tsx";
        };
        build = {
          exec = rooted ''
            cd "$REPO_ROOT"
            tsc --build
          '';
          deps = with pkgs; [typescript];
          description = "Build TypeScript project";
        };
        test = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -f "vitest.config.ts" ] || [ -f "vite.config.ts" ]; then
              vitest
            else
              echo "No Vitest config found. Install vitest and create config to run tests."
            fi
          '';
          deps = with pkgs; [vitest];
          description = "Run tests with Vitest";
        };
        clean = {
          exec = rooted ''
            cd "$REPO_ROOT"
            rm -rf dist/ build/ .turbo/ node_modules/.cache/
            echo "Build artifacts cleaned!"
          '';
          description = "Clean build artifacts";
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
            nodePackages.npm
            yarn
            nodePackages.pnpm
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

            # Development tools
            nodePackages.typescript
            nodePackages."@types/node"
            vitest # Modern testing framework
            playwright-driver # E2E testing

            # CSS and styling
            tailwindcss
            postcss
            nodePackages.autoprefixer

            # Build tools
            vite
            webpack
            parcel

            # Utility tools
            jq # JSON processing
            nodePackages.concurrently # Run multiple commands
            nodePackages.nodemon # File watching
          ]
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
          echo "🚀 TypeScript Development Environment"
          echo "📦 TypeScript version: $(tsc --version)"
          echo "📦 Node.js version: $(node --version)"
          echo ""
          echo "🛠️  Available Tools:"
          echo "   • typescript     - TypeScript compiler"
          echo "   • tsx           - Fast TypeScript execution"
          echo "   • eslint        - JavaScript/TypeScript linter"
          echo "   • oxlint        - Fast Rust-based linter"
          echo "   • biome         - All-in-one formatter and linter"
          echo "   • prettier      - Code formatter"
          echo "   • vitest        - Testing framework"
          echo ""
          echo "📚 Package Managers Available:"
          echo "   • npm           - Node Package Manager"
          echo "   • yarn          - Yarn package manager"
          echo "   • pnpm          - Fast, disk space efficient package manager"
          echo "   • bun           - Fast all-in-one JavaScript runtime"
          echo ""
          echo "🚀 Quick Commands:"
          echo "   • init-ts       - Initialize TypeScript project"
          echo "   • init-package  - Initialize package.json"
          echo "   • dev           - Start development server"
          echo "   • typecheck     - Run TypeScript type checking"
          echo "   • lint-eslint   - Lint with ESLint"
          echo "   • lint-oxlint   - Lint with oxlint"
          echo "   • lint-biome    - Lint with Biome"
          echo "   • format-prettier - Format with Prettier"
          echo "   • format-biome  - Format with Biome"
          echo "   • build         - Build TypeScript project"
          echo "   • test          - Run tests with Vitest"
          echo "   • clean         - Clean build artifacts"
          echo ""
          echo "💡 Try: 'init-ts && init-package' to set up a new TypeScript project!"
          echo "💡 Try: 'nix fmt' to format Nix code!"
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