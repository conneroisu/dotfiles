{
  description = "A development shell for Remix JS with bun";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    # Uncomment to enable bun2nix for building Bun packages with Nix
    # bun2nix.url = "github:baileyluTCD/bun2nix";
    # bun2nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs @ {
    nixpkgs,
    flake-utils,
    treefmt-nix,
    # bun2nix,
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

      scripts = {
        dx = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/flake.nix'';
          description = "Edit flake.nix";
        };
        rx = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/remix.config.js'';
          description = "Edit remix.config.js";
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
        name = "dev";

        # Available packages on https://search.nixos.org/packages
        packages = with pkgs;
          [
            bun
            nodejs
            yarn
            prettier
            eslint
            typescript
            # Uncomment to add bun2nix
            # bun2nix.packages.${system}.default
          ]
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
          echo "Welcome to the remix-js devshell!"
        '';
      };
    });

    # Uncomment to build packages with bun2nix
    # packages = forAllSystems (system: let
    #   pkgs = import nixpkgs {
    #     inherit system;
    #   };
    # in {
    #   # Example package using mkBunDerivation
    #   # my-remix-app = pkgs.callPackage ./default.nix {
    #   #   inherit (bun2nix.lib.${system}) mkBunDerivation;
    #   # };
    # });

      formatter = let
        treefmtModule = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true; # Nix formatter
          };
        };
      in
        treefmt-nix.lib.mkWrapper pkgs treefmtModule;
    });
# To use bun2nix:
# 1. Uncomment the bun2nix input and binary cache configuration
# 2. Uncomment the bun2nix package in devShells.default.packages
# 3. Add this postinstall script to your package.json:
#    "scripts": {
#      "postinstall": "bun2nix -o bun.nix"
#    }
# 4. Run 'bun install' to generate bun.nix
# 5. Uncomment and configure the packages section to build your app
# 6. Modify default.nix for your specific build requirements

