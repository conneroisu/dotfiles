/**
# Python Development Shell Template

## Description
Comprehensive Python development environment with modern tooling for building
high-quality Python applications. Features the latest Python versions, advanced
type checking, linting, formatting, testing frameworks, and package management
for productive Python development.

## Platform Support
- ✅ x86_64-linux
- ✅ aarch64-linux (ARM64 Linux)
- ✅ x86_64-darwin (Intel macOS)
- ✅ aarch64-darwin (Apple Silicon macOS)

## What This Provides
- **Python Versions**: Python 3.11, 3.12 with pip, venv support
- **Type Checking**: basedpyright (Pylance), mypy for static analysis
- **Linting & Formatting**: ruff (fast linter), black (formatter), isort (import sorting)
- **Package Management**: pip, pipenv, poetry, uv (fast package manager)
- **Testing**: pytest, coverage, hypothesis for property-based testing
- **Development Tools**: IPython, Jupyter, pre-commit hooks
- **Profiling**: py-spy, memory-profiler, line-profiler

## Key Features
- **Modern Type Checking**: basedpyright for advanced type analysis
- **Lightning Fast Linting**: ruff for ultra-fast Python linting
- **Multiple Package Managers**: Choose between pip, poetry, pipenv, or uv
- **Comprehensive Testing**: pytest with plugins and coverage
- **Interactive Development**: IPython and Jupyter notebook support
- **Performance Analysis**: Multiple profiling tools included

## Usage
```bash
# Create new project from template
nix flake init -t github:conneroisu/dotfiles#python-shell

# Enter development shell
nix develop

# Run development server
dev

# Run tests
test
```

## Development Workflow
- Use poetry or pip for dependency management
- basedpyright for advanced type checking
- ruff for lightning-fast linting
- black + isort for consistent formatting
- pytest for comprehensive testing
*/
{
  description = "A development shell for Python";

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
        name = "python-dev";

        # Available packages on https://search.nixos.org/packages
        packages = with pkgs;
          [
            # Nix tooling
            alejandra
            nixd
            statix
            deadnix

            # Python interpreter and package managers
            uv # Best

            # Type checking and linting
            pyrefly # Advanced type checker (Pylance)
            mypy # Static type checker
            ruff # Fast Python linter and formatter
            black # Code formatter
            isort # Import sorter

            # Development utilities
            git
            curl
            jq
          ]
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
          # Set up Python environment
          export PYTHONPATH="$PWD/src:$PYTHONPATH"
          export PYTHONDONTWRITEBYTECODE=1
          export PYTHONUNBUFFERED=1
        '';
      };

      packages = {
        # Example Python package build (uncomment and customize)
        # default = pkgs.python312Packages.buildPythonApplication {
        #   pname = "my-python-app";
        #   version = "0.1.0";
        #   src = ./.;
        #   propagatedBuildInputs = with pkgs.python312Packages; [
        #     requests
        #     click
        #   ];
        #   checkInputs = with pkgs.python312Packages; [
        #     pytest
        #     pytest-cov
        #   ];
        #   checkPhase = ''
        #     pytest
        #   '';
        #   meta = with pkgs.lib; {
        #     description = "My Python application";
        #     homepage = "https://github.com/user/my-python-app";
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
            black.enable = true; # Python formatter
            isort.enable = true; # Python import sorter
            ruff.enable = true; # Python linter/formatter
          };
          settings = {
            formatter = {
              black = {
                options = ["--line-length" "88"];
                includes = ["*.py"];
              };
              isort = {
                options = ["--profile" "black"];
                includes = ["*.py"];
              };
              ruff = {
                options = ["--fix"];
                includes = ["*.py"];
              };
            };
          };
        };
      in
        treefmt-nix.lib.mkWrapper pkgs treefmtModule;
    });
}
