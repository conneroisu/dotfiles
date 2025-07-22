{
  description = "Connix API";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    crane.url = "github:ipetkov/crane";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    rust-overlay,
    crane,
    treefmt-nix,
    ...
  }: let
    # Define systems
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    # Helper function to generate per-system attributes
    forAllSystems = f: nixpkgs.lib.genAttrs systems f;
  in {
    # Define devShells for all systems
    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          rust-overlay.overlays.default
          # Build all go packages with go124
          (final: prev: {
            buildGoModule = prev.buildGo124Module;
          })
        ];
      };

      rooted = exec:
        builtins.concatStringsSep "\n"
        [
          ''
            REPO_ROOT="$(git rev-parse --show-toplevel)"
          ''
          exec
        ];

      scripts = {
        dx = {
          exec = rooted ''
            $EDITOR "$REPO_ROOT"/flake.nix
          '';
          deps = [pkgs.git];
          description = "Edit flake.nix";
        };
        lint = {
          exec = rooted ''
            cd "$REPO_ROOT"/
            eslint --fix .
          '';
          deps = [pkgs.eslint];
          description = "Lint the project";
        };
      };
      scriptPackages =
        pkgs.lib.mapAttrs
        (
          name: script: let
            scriptType = script.type or "app";
          in
            if scriptType == "script"
            then pkgs.writeShellScriptBin name script.exec
            else
              pkgs.writeShellApplication {
                inherit name;
                bashOptions = scripts.baseOptions or ["errexit" "pipefail" "nounset"];
                text = script.exec;
                runtimeInputs = script.deps or [];
              }
        )
        scripts;
    in {
      default = pkgs.mkShell {
        name = "dev";
        # Available packages on https://search.nixos.org/packages
        env = {
        };
        buildInputs =
          [
            pkgs.alejandra # Nix
            pkgs.nixd
            pkgs.statix
            pkgs.deadnix
            pkgs.just
            pkgs.flyctl
            pkgs.rust-bin.stable.latest.default
            pkgs.rust-bin.stable.latest.rust-analyzer
            pkgs.go
            pkgs.doppler
            pkgs.typescript-language-server
            pkgs.vscode-langservers-extracted
            pkgs.nodePackages.prettier
            pkgs.eslint
            pkgs.tailwindcss-language-server
            pkgs.go_1_24 # Go Tools
            pkgs.gomarkdoc
            pkgs.air
            pkgs.templ
            pkgs.nodejs
            pkgs.golangci-lint
            pkgs.golangci-lint-langserver
            pkgs.oxlint
            pkgs.cobra-cli
            pkgs.revive
            pkgs.gopls
            pkgs.bun
          ]
          ++ builtins.attrValues scriptPackages;
        shellHook = ''
        '';
      };
    });

    packages = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [rust-overlay.overlays.default];
      };
    in {
      default = pkgs.stdenv.mkDerivation {
        pname = "connix-api";
        version = "0.1.0";

        src = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter = path: type: let
            basename = baseNameOf path;
          in
            !(pkgs.lib.hasInfix "node_modules" path)
            && !(pkgs.lib.hasInfix ".git" path)
            && !(pkgs.lib.hasInfix ".output" path)
            && !(pkgs.lib.hasInfix "result" path)
            && !(basename == ".direnv")
            && !(basename == "target")
            && !(basename == "__pycache__");
        };

        nativeBuildInputs = [
          pkgs.bun
          pkgs.nodejs
          pkgs.cacert
        ];

        configurePhase = ''
          runHook preConfigure

          export HOME=$(mktemp -d)
          export BUN_INSTALL_CACHE_DIR=$HOME/.bun/cache

          runHook postConfigure
        '';

        buildPhase = ''
          runHook preBuild

          export NODE_OPTIONS="--max-old-space-size=4096 --max-semi-space-size=128"

          # Install dependencies with Bun
          bun install --cores=4 --max-jobs=4

          # Build the project
          bun run build

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/lib/connix-api
          cp -r .output/* $out/lib/connix-api/

          mkdir -p $out/bin
          cat > $out/bin/connix-api <<EOF
          #!/bin/sh
          exec ${pkgs.nodejs}/bin/node $out/lib/connix-api/server/index.mjs "\$@"
          EOF
          chmod +x $out/bin/connix-api

          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "Connix API server";
          homepage = "https://github.com/connix/api";
          license = licenses.mit;
          maintainers = [];
        };
      };
    });

    formatter = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [rust-overlay.overlays.default];
      };
      treefmtModule = {
        projectRootFile = "flake.nix";
        programs = {
          alejandra.enable = true; # Nix formatter
          rustfmt.enable = true; # Rust formatter
          prettier.enable = true; # Prettier formatter
          gofmt.enable = true; # Go formatter
          golines.enable = true; # Golines formatter
        };
      };
    in
      treefmt-nix.lib.mkWrapper pkgs treefmtModule);
  };
}
