{
  description = "Dev shell for TLA+ / Apalache / Alloy with handy scripts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Formatting (optional but nice)
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
        overlays = [
          (final: prev: {
            # Overlays spot, if you need to pin or adjust anything later.
            # Example: final.buildGoModule = prev.buildGo124Module;
          })
        ];
      };

      # Helper to make scripts repo-root aware and exec the payload
      rooted = exec:
        builtins.concatStringsSep "\n" [
          ''REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"''
          exec
        ];

      # Common deps for scripts
      jdk = pkgs.jdk17;
      inherit (pkgs) tlaplusToolbox tlaplus alloy;

      # Repo-focused scripts for TLA+ / Alloy projects
      scripts = {
        # --- Quality of life
        dx = {
          description = "Edit flake.nix";
          exec = rooted ''"$EDITOR" "$REPO_ROOT"/flake.nix'';
          deps = [pkgs.bash];
        };
      };

      # Turn the scripts attrset into actual packages
      scriptPackages =
        pkgs.lib.mapAttrs
        (name: script:
          pkgs.writeShellApplication {
            inherit name;
            text = script.exec;
            runtimeInputs = script.deps or [];
          })
        scripts;

      treefmtModule = {
        projectRootFile = "flake.nix";
        programs.alejandra.enable = true;
      };
    in {
      devShells.default = pkgs.mkShell {
        name = "tla-alloy-dev";
        packages =
          (with pkgs; [
            # Java & tools
            jdk

            # Formal tools
            tlaplus
            tlaplusToolbox
            alloy
            graphviz

            # Nix / editor helpers
            alejandra
            nixd
            statix
            deadnix
            direnv
            git
            jq
            fd
            ripgrep
          ])
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
          export JAVA_HOME=${jdk}
          echo "[tla-alloy-dev] JAVA_HOME set → ${jdk}"
          if [ -f .envrc ]; then
            echo "direnv: .envrc detected (run 'direnv allow' if first time)."
          else
            echo "Tip: echo 'use flake' > .envrc && direnv allow"
          fi
        '';
      };

      # Expose scripts as `nix run .#tla:tlc` etc.
      apps =
        pkgs.lib.mapAttrs (n: p: {
          type = "app";
          program = "${p}/bin/${n}";
        })
        scriptPackages;

      # Formatter (treefmt wrapper)
      formatter = treefmt-nix.lib.mkWrapper pkgs treefmtModule;
    });
}
