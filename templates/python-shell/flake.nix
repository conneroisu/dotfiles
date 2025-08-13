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

# Initialize Python project
init-poetry  # or init-pip

# Run development server
dev

# Format and lint code
format && lint

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

      # Python with common packages
      pythonEnv = pkgs.python312.withPackages (ps:
        with ps; [
          pip
          setuptools
          wheel
          virtualenv
          # Development tools that need to be in Python env
          ipython
          jupyter
          notebook
          jupyterlab
        ]);

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
        px = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/pyproject.toml'';
          description = "Edit pyproject.toml";
        };
        rx = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/requirements.txt'';
          description = "Edit requirements.txt";
        };
        init-poetry = {
          exec = rooted ''
                        cd "$REPO_ROOT"
                        if [ ! -f pyproject.toml ]; then
                          poetry init --no-interaction \
                            --name "$(basename "$REPO_ROOT")" \
                            --version "0.1.0" \
                            --description "A Python project" \
                            --author "$(git config user.name) <$(git config user.email)>" \
                            --python "^3.11"

                          # Add common development dependencies
                          poetry add --group dev pytest pytest-cov pytest-mock pytest-asyncio
                          poetry add --group dev black isort ruff mypy
                          poetry add --group dev pre-commit

                          # Create basic project structure
                          mkdir -p src tests docs

                          cat > src/__init__.py << 'EOF'
            """Main package module."""

            __version__ = "0.1.0"
            EOF

                          cat > src/main.py << 'EOF'
            """Main application module."""

            import sys
            from typing import List


            def main(args: List[str] | None = None) -> int:
                """Main entry point for the application.

                Args:
                    args: Command line arguments (defaults to sys.argv[1:])

                Returns:
                    Exit code (0 for success)
                """
                if args is None:
                    args = sys.argv[1:]

                print("Hello, Python!")
                print(f"Arguments: {args}")

                return 0


            if __name__ == "__main__":
                sys.exit(main())
            EOF

                          cat > tests/__init__.py << 'EOF'
            """Test package."""
            EOF

                          cat > tests/test_main.py << 'EOF'
            """Tests for main module."""

            import pytest
            from src.main import main


            def test_main_no_args():
                """Test main function with no arguments."""
                result = main([])
                assert result == 0


            def test_main_with_args():
                """Test main function with arguments."""
                result = main(["arg1", "arg2"])
                assert result == 0


            @pytest.mark.parametrize("args,expected", [
                ([], 0),
                (["test"], 0),
                (["arg1", "arg2"], 0),
            ])
            def test_main_parametrized(args, expected):
                """Parametrized test for main function."""
                assert main(args) == expected
            EOF

                          cat > .pre-commit-config.yaml << 'EOF'
            repos:
              - repo: https://github.com/pre-commit/pre-commit-hooks
                rev: v4.4.0
                hooks:
                  - id: trailing-whitespace
                  - id: end-of-file-fixer
                  - id: check-yaml
                  - id: check-added-large-files
                  - id: check-toml
                  - id: check-json

              - repo: https://github.com/psf/black
                rev: 23.9.1
                hooks:
                  - id: black
                    language_version: python3

              - repo: https://github.com/pycqa/isort
                rev: 5.12.0
                hooks:
                  - id: isort
                    args: ["--profile", "black"]

              - repo: https://github.com/charliermarsh/ruff-pre-commit
                rev: v0.0.292
                hooks:
                  - id: ruff
                    args: [--fix, --exit-non-zero-on-fix]

              - repo: https://github.com/pre-commit/mirrors-mypy
                rev: v1.5.1
                hooks:
                  - id: mypy
                    additional_dependencies: [types-all]
            EOF

                          cat > .gitignore << 'EOF'
            # Byte-compiled / optimized / DLL files
            __pycache__/
            *.py[cod]
            *$py.class

            # C extensions
            *.so

            # Distribution / packaging
            .Python
            build/
            develop-eggs/
            dist/
            downloads/
            eggs/
            .eggs/
            lib/
            lib64/
            parts/
            sdist/
            var/
            wheels/
            *.egg-info/
            .installed.cfg
            *.egg

            # PyInstaller
            *.manifest
            *.spec

            # Installer logs
            pip-log.txt
            pip-delete-this-directory.txt

            # Unit test / coverage reports
            htmlcov/
            .tox/
            .coverage
            .coverage.*
            .cache
            nosetests.xml
            coverage.xml
            *.cover
            .hypothesis/
            .pytest_cache/

            # Jupyter Notebook
            .ipynb_checkpoints

            # pyenv
            .python-version

            # pipenv
            Pipfile.lock

            # poetry
            poetry.lock

            # Environments
            .env
            .venv
            env/
            venv/
            ENV/
            env.bak/
            venv.bak/

            # mypy
            .mypy_cache/
            .dmypy.json
            dmypy.json

            # IDEs
            .vscode/
            .idea/
            *.swp
            *.swo
            *~

            # OS
            .DS_Store
            Thumbs.db
            EOF

                          echo "Poetry project initialized with modern Python setup!"
                          echo "Project structure created:"
                          echo "  - pyproject.toml (Poetry configuration)"
                          echo "  - src/ (source code directory)"
                          echo "  - tests/ (test directory with pytest examples)"
                          echo "  - .pre-commit-config.yaml (pre-commit hooks)"
                          echo "  - .gitignore (comprehensive Python gitignore)"
                          echo ""
                          echo "Next steps:"
                          echo "  1. Run 'poetry install' to install dependencies"
                          echo "  2. Run 'pre-commit install' to set up git hooks"
                          echo "  3. Run 'test' to run the example tests"
                        else
                          echo "pyproject.toml already exists"
                        fi
          '';
          deps = with pkgs; [poetry git];
          description = "Initialize Poetry project with modern Python setup";
        };
        init-pip = {
          exec = rooted ''
                        cd "$REPO_ROOT"
                        if [ ! -f requirements.txt ]; then
                          cat > requirements.txt << 'EOF'
            # Production dependencies
            requests>=2.31.0
            click>=8.1.0

            # Development dependencies (install with: pip install -r requirements-dev.txt)
            EOF

                          cat > requirements-dev.txt << 'EOF'
            # Testing
            pytest>=7.4.0
            pytest-cov>=4.1.0
            pytest-mock>=3.11.0
            pytest-asyncio>=0.21.0
            hypothesis>=6.82.0

            # Linting and formatting
            ruff>=0.0.292
            black>=23.9.0
            isort>=5.12.0
            mypy>=1.5.0

            # Type checking
            basedpyright>=1.10.0

            # Development tools
            pre-commit>=3.4.0
            ipython>=8.15.0
            jupyterlab>=4.0.0

            # Profiling
            py-spy>=0.3.14
            memory-profiler>=0.61.0
            line-profiler>=4.1.0
            EOF

                          cat > setup.py << 'EOF'
            """Setup script for the project."""

            from setuptools import setup, find_packages

            with open("README.md", "r", encoding="utf-8") as fh:
                long_description = fh.read()

            with open("requirements.txt", "r", encoding="utf-8") as fh:
                requirements = [line.strip() for line in fh if line.strip() and not line.startswith("#")]

            setup(
                name="my-python-project",
                version="0.1.0",
                author="Your Name",
                author_email="your.email@example.com",
                description="A Python project",
                long_description=long_description,
                long_description_content_type="text/markdown",
                packages=find_packages(),
                classifiers=[
                    "Development Status :: 3 - Alpha",
                    "Intended Audience :: Developers",
                    "License :: OSI Approved :: MIT License",
                    "Operating System :: OS Independent",
                    "Programming Language :: Python :: 3",
                    "Programming Language :: Python :: 3.11",
                    "Programming Language :: Python :: 3.12",
                ],
                python_requires=">=3.11",
                install_requires=requirements,
                entry_points={
                    "console_scripts": [
                        "my-app=src.main:main",
                    ],
                },
            )
            EOF

                          # Create basic project structure
                          mkdir -p src tests docs

                          cat > src/__init__.py << 'EOF'
            """Main package module."""

            __version__ = "0.1.0"
            EOF

                          cat > src/main.py << 'EOF'
            """Main application module."""

            import sys
            from typing import List


            def main(args: List[str] | None = None) -> int:
                """Main entry point for the application.

                Args:
                    args: Command line arguments (defaults to sys.argv[1:])

                Returns:
                    Exit code (0 for success)
                """
                if args is None:
                    args = sys.argv[1:]

                print("Hello, Python!")
                print(f"Arguments: {args}")

                return 0


            if __name__ == "__main__":
                sys.exit(main())
            EOF

                          cat > tests/__init__.py << 'EOF'
            """Test package."""
            EOF

                          cat > tests/test_main.py << 'EOF'
            """Tests for main module."""

            import pytest
            from src.main import main


            def test_main_no_args():
                """Test main function with no arguments."""
                result = main([])
                assert result == 0


            def test_main_with_args():
                """Test main function with arguments."""
                result = main(["arg1", "arg2"])
                assert result == 0


            @pytest.mark.parametrize("args,expected", [
                ([], 0),
                (["test"], 0),
                (["arg1", "arg2"], 0),
            ])
            def test_main_parametrized(args, expected):
                """Parametrized test for main function."""
                assert main(args) == expected
            EOF

                          echo "Pip-based project initialized!"
                          echo "Files created:"
                          echo "  - requirements.txt (production dependencies)"
                          echo "  - requirements-dev.txt (development dependencies)"
                          echo "  - setup.py (package configuration)"
                          echo "  - src/ (source code directory)"
                          echo "  - tests/ (test directory)"
                          echo ""
                          echo "Next steps:"
                          echo "  1. Run 'pip install -r requirements-dev.txt' to install dependencies"
                          echo "  2. Run 'pip install -e .' to install package in development mode"
                          echo "  3. Run 'test' to run the example tests"
                        else
                          echo "requirements.txt already exists"
                        fi
          '';
          deps = with pkgs; [pythonEnv];
          description = "Initialize pip-based project";
        };
        dev = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -f src/main.py ]; then
              echo "Starting development mode..."
              python src/main.py
            elif [ -f main.py ]; then
              python main.py
            else
              echo "No main.py found in src/ or root directory"
              echo "Create one to start development"
            fi
          '';
          deps = [pythonEnv];
          description = "Run main Python application";
        };
        test = {
          exec = rooted ''
            cd "$REPO_ROOT"
            pytest -v --cov=src --cov-report=html --cov-report=term
          '';
          deps = with pkgs; [pythonPackages.pytest pythonPackages.pytest-cov];
          description = "Run tests with coverage";
        };
        test-watch = {
          exec = rooted ''
            cd "$REPO_ROOT"
            pytest-watch -- -v --cov=src
          '';
          deps = with pkgs; [pythonPackages.pytest pythonPackages.pytest-cov pythonPackages.pytest-watch];
          description = "Run tests in watch mode";
        };
        lint = {
          exec = rooted ''
            cd "$REPO_ROOT"
            echo "🔍 Running ruff..."
            ruff check . --fix
            echo "✅ Ruff completed"

            echo "🔍 Running mypy..."
            mypy src/ || true
            echo "✅ Mypy completed"

            echo "🔍 Running basedpyright..."
            basedpyright src/ || true
            echo "✅ basedpyright completed"
          '';
          deps = with pkgs; [ruff mypy basedpyright];
          description = "Run all linting tools";
        };
        lint-ruff = {
          exec = rooted ''
            cd "$REPO_ROOT"
            ruff check . --fix
          '';
          deps = [pkgs.ruff];
          description = "Lint with ruff";
        };
        lint-mypy = {
          exec = rooted ''
            cd "$REPO_ROOT"
            mypy src/
          '';
          deps = [pkgs.mypy];
          description = "Type check with mypy";
        };
        lint-basedpyright = {
          exec = rooted ''
            cd "$REPO_ROOT"
            basedpyright src/
          '';
          deps = [pkgs.basedpyright];
          description = "Type check with basedpyright";
        };
        format = {
          exec = rooted ''
            cd "$REPO_ROOT"
            echo "🎨 Running isort..."
            isort .
            echo "✅ isort completed"

            echo "🎨 Running black..."
            black .
            echo "✅ black completed"
          '';
          deps = with pkgs; [black isort];
          description = "Format code with black and isort";
        };
        format-black = {
          exec = rooted ''
            cd "$REPO_ROOT"
            black .
          '';
          deps = [pkgs.black];
          description = "Format with black";
        };
        format-isort = {
          exec = rooted ''
            cd "$REPO_ROOT"
            isort .
          '';
          deps = [pkgs.isort];
          description = "Sort imports with isort";
        };
        notebook = {
          exec = rooted ''
            cd "$REPO_ROOT"
            jupyter lab
          '';
          deps = [pythonEnv];
          description = "Start Jupyter Lab";
        };
        repl = {
          exec = rooted ''
            cd "$REPO_ROOT"
            ipython
          '';
          deps = [pythonEnv];
          description = "Start IPython REPL";
        };
        profile-time = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -f src/main.py ]; then
              python -m cProfile -s cumulative src/main.py
            else
              echo "No src/main.py found to profile"
            fi
          '';
          deps = [pythonEnv];
          description = "Profile execution time";
        };
        profile-memory = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -f src/main.py ]; then
              python -m memory_profiler src/main.py
            else
              echo "No src/main.py found to profile"
              echo "Add @profile decorator to functions you want to profile"
            fi
          '';
          deps = with pkgs; [pythonPackages.memory-profiler];
          description = "Profile memory usage";
        };
        deps-install = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -f pyproject.toml ]; then
              poetry install
            elif [ -f requirements-dev.txt ]; then
              pip install -r requirements-dev.txt
              pip install -e .
            elif [ -f requirements.txt ]; then
              pip install -r requirements.txt
            else
              echo "No dependency file found (pyproject.toml, requirements.txt)"
            fi
          '';
          deps = with pkgs; [poetry pythonEnv];
          description = "Install project dependencies";
        };
        deps-update = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -f pyproject.toml ]; then
              poetry update
            else
              echo "Poetry project not detected. Use deps-install for pip-based projects."
            fi
          '';
          deps = [pkgs.poetry];
          description = "Update dependencies (Poetry only)";
        };
        clean = {
          exec = rooted ''
            cd "$REPO_ROOT"
            find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
            find . -type f -name "*.pyc" -delete 2>/dev/null || true
            find . -type f -name "*.pyo" -delete 2>/dev/null || true
            find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
            rm -rf .pytest_cache/ .coverage htmlcov/ .mypy_cache/ 2>/dev/null || true
            echo "Python cache files cleaned!"
          '';
          description = "Clean Python cache files and artifacts";
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
            pythonEnv
            poetry
            pipenv
            uv # Fast Python package installer

            # Type checking and linting
            basedpyright # Advanced type checker (Pylance)
            mypy # Static type checker
            ruff # Fast Python linter and formatter
            black # Code formatter
            isort # Import sorter

            # Testing
            pythonPackages.pytest
            pythonPackages.pytest-cov
            pythonPackages.pytest-mock
            pythonPackages.pytest-asyncio
            pythonPackages.pytest-watch
            pythonPackages.hypothesis # Property-based testing
            pythonPackages.tox # Testing across Python versions

            # Development tools
            pythonPackages.pre-commit
            pythonPackages.flake8 # Alternative linter
            pythonPackages.bandit # Security linter
            pythonPackages.safety # Security vulnerability checker

            # Profiling and debugging
            pythonPackages.py-spy # Sampling profiler
            pythonPackages.memory-profiler # Memory profiler
            pythonPackages.line-profiler # Line-by-line profiler
            pythonPackages.pyflame # Profiling tool

            # Documentation
            pythonPackages.sphinx # Documentation generator
            pythonPackages.mkdocs # Modern documentation
            pythonPackages.pdoc # Simple API documentation

            # Jupyter and interactive development
            # (included in pythonEnv)

            # Build tools
            pythonPackages.build # PEP 517 build tool
            pythonPackages.twine # PyPI upload tool
            pythonPackages.wheel # Wheel building

            # Popular libraries (optional, uncomment as needed)
            # pythonPackages.requests
            # pythonPackages.numpy
            # pythonPackages.pandas
            # pythonPackages.matplotlib
            # pythonPackages.seaborn
            # pythonPackages.scikit-learn
            # pythonPackages.flask
            # pythonPackages.django
            # pythonPackages.fastapi
            # pythonPackages.sqlalchemy
            # pythonPackages.pydantic
            # pythonPackages.click
            # pythonPackages.typer

            # Development utilities
            git
            curl
            jq
          ]
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
          echo "🐍 Python Development Environment"
          echo "📦 Python version: $(python --version)"
          echo "📦 Poetry version: $(poetry --version 2>/dev/null || echo 'not available')"
          echo ""
          echo "🛠️  Available Tools:"
          echo "   • python        - Python 3.12 interpreter"
          echo "   • poetry        - Modern dependency management"
          echo "   • uv            - Fast package installer"
          echo "   • basedpyright  - Advanced type checker (Pylance)"
          echo "   • mypy          - Static type checker"
          echo "   • ruff          - Lightning-fast linter and formatter"
          echo "   • black         - Code formatter"
          echo "   • isort         - Import sorter"
          echo "   • pytest        - Testing framework"
          echo ""
          echo "📦 Package Managers:"
          echo "   • poetry        - Modern Python packaging"
          echo "   • pip           - Standard package installer"
          echo "   • pipenv        - pip + virtualenv wrapper"
          echo "   • uv            - Fast package installer"
          echo ""
          echo "🧪 Testing & Quality:"
          echo "   • pytest        - Testing framework with plugins"
          echo "   • hypothesis    - Property-based testing"
          echo "   • coverage      - Code coverage analysis"
          echo "   • bandit        - Security vulnerability scanner"
          echo "   • safety        - Dependency vulnerability checker"
          echo ""
          echo "📊 Profiling Tools:"
          echo "   • py-spy        - Sampling profiler"
          echo "   • memory-profiler - Memory usage profiler"
          echo "   • line-profiler  - Line-by-line profiler"
          echo "   • cProfile      - Built-in profiler"
          echo ""
          echo "🚀 Quick Commands:"
          echo "   • init-poetry   - Initialize Poetry project"
          echo "   • init-pip      - Initialize pip-based project"
          echo "   • dev           - Run main application"
          echo "   • test          - Run tests with coverage"
          echo "   • test-watch    - Run tests in watch mode"
          echo "   • lint          - Run all linting tools"
          echo "   • format        - Format code (black + isort)"
          echo "   • notebook      - Start Jupyter Lab"
          echo "   • repl          - Start IPython REPL"
          echo "   • deps-install  - Install dependencies"
          echo "   • profile-time  - Profile execution time"
          echo "   • profile-memory - Profile memory usage"
          echo "   • clean         - Clean cache files"
          echo ""
          echo "💡 Try: 'init-poetry && deps-install && test' to set up a Python project!"
          echo "💡 Try: 'nix fmt' to format Nix code!"

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
