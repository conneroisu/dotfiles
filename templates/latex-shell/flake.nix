/**
# LaTeX Development Shell Template

## Description
Complete LaTeX development environment with Overleaf-equivalent functionality.
Provides full TeX Live distribution, live preview, spell checking, grammar checking,
bibliography management, and collaborative tools for professional document preparation.

## Platform Support
- ✅ x86_64-linux
- ✅ aarch64-linux (ARM64 Linux)
- ✅ x86_64-darwin (Intel macOS)
- ✅ aarch64-darwin (Apple Silicon macOS)

## What This Provides
- **Full TeX Live**: Complete LaTeX distribution with all packages
- **Live Preview**: latexmk with continuous compilation and PDF preview
- **Editors**: texlab (LSP), texstudio, or use with VSCode/Neovim
- **Bibliography**: biber, biblatex, BibTeX for reference management
- **Spell/Grammar**: aspell, hunspell, languagetool for proofreading
- **Graphics**: inkscape, imagemagick for figure creation/conversion
- **Version Control**: git-latexdiff for tracking document changes
- **Formatting**: latexindent for code formatting
- **Tables**: excel2latex workflow tools
- **Collaboration**: git hooks and diff tools for team workflows

## Usage
```bash
# Enter development shell
nix develop

# Compile LaTeX document with live preview
latexmk -pdf -pvc main.tex

# Compile with specific engine
latexmk -xelatex main.tex
latexmk -lualatex main.tex

# Clean auxiliary files
latexmk -c

# Spell check
aspell check document.tex

# Grammar check
languagetool document.tex

# Format LaTeX code
latexindent -w main.tex

# View PDF
evince main.pdf  # or okular

# Generate diff between git commits
git-latexdiff HEAD~1 HEAD --main main.tex
```

## Overleaf Feature Parity
- ✅ Full LaTeX compilation (pdflatex, xelatex, lualatex)
- ✅ Live preview and auto-recompilation
- ✅ Comprehensive package library (full TeX Live)
- ✅ Bibliography management (BibTeX, Biber, BibLaTeX)
- ✅ Spell checking and grammar checking
- ✅ Git-based version control (superior to Overleaf)
- ✅ Rich text preview
- ✅ Error logs and warnings
- ✅ Multiple compiler support
- ✅ Template support
- ✅ Collaborative editing (via git)

## Development Workflow
- Edit .tex files in your preferred editor (VSCode, Neovim, Emacs, etc.)
- Use latexmk -pvc for continuous compilation
- View PDF with automatic refresh in evince/okular
- Use git for version control and collaboration
- Run spell/grammar checks before finalizing
*/
{
  description = "A complete LaTeX development environment with Overleaf-equivalent features";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    self,
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

      # Helper scripts for common LaTeX workflows
      scripts = {
        dx = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/flake.nix'';
          description = "Edit flake.nix";
        };
        ltx-compile = {
          exec = ''
            if [ -z "$1" ]; then
              echo "Usage: ltx-compile <file.tex> [engine]"
              echo "Engines: pdf (default), xe, lua"
              exit 1
            fi
            ENGINE="''${2:-pdf}"
            latexmk -"$ENGINE"latex -interaction=nonstopmode -file-line-error "$1"
          '';
          description = "Compile LaTeX document";
          deps = with pkgs; [texliveFull];
        };
        ltx-watch = {
          exec = ''
            if [ -z "$1" ]; then
              echo "Usage: ltx-watch <file.tex> [engine]"
              echo "Engines: pdf (default), xe, lua"
              exit 1
            fi
            ENGINE="''${2:-pdf}"
            latexmk -"$ENGINE"latex -pvc -interaction=nonstopmode -file-line-error "$1"
          '';
          description = "Watch and auto-compile LaTeX document";
          deps = with pkgs; [texliveFull];
        };
        ltx-clean = {
          exec = ''
            latexmk -c "''${1:-.}"
            echo "Cleaned auxiliary files"
          '';
          description = "Clean LaTeX auxiliary files";
          deps = with pkgs; [texliveFull];
        };
        ltx-spell = {
          exec = ''
            if [ -z "$1" ]; then
              echo "Usage: ltx-spell <file.tex>"
              exit 1
            fi
            aspell --mode=tex --lang=en check "$1"
          '';
          description = "Spell check LaTeX document";
          deps = with pkgs; [aspell aspellDicts.en];
        };
        ltx-wordcount = {
          exec = ''
            if [ -z "$1" ]; then
              echo "Usage: ltx-wordcount <file.tex>"
              exit 1
            fi
            texcount -inc -incbib "$1"
          '';
          description = "Count words in LaTeX document";
          deps = with pkgs; [texliveFull];
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
        };
      };
    in {
      devShells.default = pkgs.mkShell {
        name = "latex-dev";

        # Available packages on https://search.nixos.org/packages
        packages = with pkgs;
          [
            # Nix tooling
            alejandra
            nixd
            statix
            deadnix

            # Core LaTeX - Full TeX Live distribution
            texliveFull # Includes all LaTeX packages, fonts, and tools

            # LaTeX language server and IDE support
            texlab # LSP for LaTeX
            ltex-ls # Grammar/spell checking LSP

            # Bibliography and reference management
            jabref # GUI for managing BibTeX databases
            bibtool # BibTeX manipulation tool

            # Spell and grammar checking
            aspell
            aspellDicts.en
            aspellDicts.en-computers
            hunspell
            hunspellDicts.en_US
            languagetool # Advanced grammar checking

            # PDF viewers with auto-reload
            evince # GNOME document viewer

            # Graphics and figure tools
            inkscape # Vector graphics editor
            imagemagick # Image manipulation
            graphviz # Graph visualization
            gnuplot # Plotting tool

            # Diff and version control tools
            git
            git-latexdiff # Generate diffs for LaTeX documents

            # Python tools for LaTeX workflows
            python3
            python3Packages.pygments # Syntax highlighting in LaTeX

            # Additional utilities
            pandoc # Document conversion (Markdown ↔ LaTeX)
            ghostscript # PostScript/PDF manipulation
            poppler_utils # PDF utilities (pdfinfo, pdftotext, etc.)

            # Spell checking dictionaries
            enchant # Generic spell checker interface

            # Make and build tools
            gnumake
            watchexec # File watcher alternative to latexmk -pvc
          ]
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
          echo "🎓 LaTeX Development Environment"
          echo "================================="
          echo ""
          echo "Quick Start:"
          echo "  ltx-watch main.tex     - Live compile with PDF preview"
          echo "  ltx-compile main.tex   - One-time compilation"
          echo "  ltx-clean              - Clean auxiliary files"
          echo "  ltx-spell document.tex - Spell check"
          echo "  ltx-wordcount main.tex - Count words"
          echo ""
          echo "Manual Commands:"
          echo "  latexmk -pdf -pvc main.tex           - Auto-compile on changes"
          echo "  latexmk -xelatex main.tex            - Compile with XeLaTeX"
          echo "  latexmk -lualatex main.tex           - Compile with LuaLaTeX"
          echo "  biber main                           - Run Biber for bibliography"
          echo "  evince main.pdf &                    - Open PDF viewer"
          echo "  git-latexdiff HEAD~1 HEAD main.tex   - Git diff visualization"
          echo "  languagetool -l en-US document.tex   - Grammar check"
          echo ""
          echo "📚 Full TeX Live distribution loaded with all packages!"
          echo "🔍 LSP servers: texlab, ltex-ls"
          echo "✨ Happy LaTeXing!"
          echo ""
        '';
      };

      formatter = treefmt-nix.lib.mkWrapper pkgs treefmtModule;
    });
}
