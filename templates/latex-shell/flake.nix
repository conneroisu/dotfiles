{
  description = "A complete LaTeX development environment with Overleaf-equivalent features";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    # Used for shell.nix
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    treefmt-nix,
    git-hooks,
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
        lint = {
          exec = ''
            chktex main.tex
            chktex sections/*.tex
            chktex poster/poster.tex
            chktex poster/poster-config.tex
            chktex poster/sections/*.tex
          '';
          description = "Lint LaTeX document(s)";
          deps = with pkgs; [
            texliveFull
          ];
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
          texfmt.enable = true; # TeX formatter
        };
      };

      preCommitCheck = git-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          chktex.enable = true;
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

            # Additional utilities
            pandoc # Document conversion (Markdown ↔ LaTeX)
            ghostscript # PostScript/PDF manipulation
            poppler_utils # PDF utilities (pdfinfo, pdftotext, etc.)
            watchexec # File watcher alternative to latexmk -pvc
          ]
          ++ builtins.attrValues scriptPackages
          ++ preCommitCheck.enabledPackages;

        shellHook =
          preCommitCheck.shellHook
          + ''
            echo "🎓 LaTeX Development Environment 🎓"
          '';
      };

      # Minimal CI/CD devShell optimized for automated builds
      devShells.ci = pkgs.mkShell {
        name = "latex-ci";

        # Minimal packages needed for CI builds and testing
        packages = with pkgs;
          [
            # Core LaTeX for compilation
            texliveFull

            # PDF utilities for validation
            poppler_utils
          ]
          ++ builtins.attrValues scriptPackages
          ++ preCommitCheck.enabledPackages;
      };

      formatter = treefmt-nix.lib.mkWrapper pkgs treefmtModule;

      checks.pre-commit-check = preCommitCheck;
    });
}
