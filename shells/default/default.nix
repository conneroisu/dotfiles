{
  lib,
  inputs,
  namespace,
  pkgs,
  mkShell,
  ...
}: let
  # Import scripts from scripts.nix
  scripts = import ./scripts.nix {inherit lib pkgs;};

  # Convert scripts to packages
  scriptPackages =
    lib.mapAttrsToList
    (name: script: pkgs.writeShellScriptBin name script.exec)
    scripts;

  buildWithSpecificGo = pkg: pkg.override {buildGoModule = pkgs.buildGo124Module;};
in
  mkShell {
    shellHook = ''
      export REPO_ROOT=$(git rev-parse --show-toplevel)
      export CGO_CFLAGS="-O2"

      # Print available commands
      echo "Available commands:"
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: script: ''echo "  ${name} - ${script.description}"'') scripts)}

      echo "Git Status:"
      git status
    '';
    packages = with pkgs;
      [
        # Nix
        alejandra
        nixd
        # Python
        ruff
        black
        isort
        basedpyright
        # Shell
        shellcheck
        go_1_24 # Go Tools
        air
        templ
        golangci-lint
        (buildWithSpecificGo revive)
        (buildWithSpecificGo gopls)
        (buildWithSpecificGo templ)
        (buildWithSpecificGo golines)
        (buildWithSpecificGo golangci-lint-langserver)
        (buildWithSpecificGo gomarkdoc)
        (buildWithSpecificGo gotests)
        (buildWithSpecificGo gotools)
        (buildWithSpecificGo reftools)
        pprof
        graphviz
      ]
      # Add the generated script packages
      ++ scriptPackages;
  }
