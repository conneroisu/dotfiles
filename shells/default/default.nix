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
        # Shell
        shellcheck
      ]
      # Add the generated script packages
      ++ scriptPackages;
  }
