{pkgs ? import <nixpkgs> {}}: let
  scripts = {
    dx = {
      exec = ''$EDITOR "$REPO_ROOT"/flake.nix'';
      description = "Edit the flake.nix";
      deps = [];
    };
    lint = {
      exec = ''
        REPO_ROOT="$(git rev-parse --show-toplevel)"
        statix check "$REPO_ROOT"/flake.nix
        deadnix "$REPO_ROOT"/flake.nix
        nix flake check "$REPO_ROOT"
      '';
      deps = with pkgs; [git statix deadnix];
      description = "Run golangci-lint";
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
in
  pkgs.mkShell {
    shellHook = ''
      export REPO_ROOT="$(git rev-parse --show-toplevel)"
      export CGO_CFLAGS="-O2"

      # Print available commands
      echo "Available commands:"
      ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: script: ''echo "  ${name} - ${script.description}"'') scripts)}

      echo "Git Status:"
      git status
    '';
    packages = with pkgs;
      [
        alejandra # Nix
        nixd

        ruff # Python
        black
        isort
        basedpyright
        luajitPackages.luacheck

        go_1_24 # Go
        air
        golangci-lint
        gopls
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

        geesefs
        sops
      ]
      ++ builtins.attrValues scriptPackages;
  }
