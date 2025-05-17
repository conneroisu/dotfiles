{
  description = "A development shell for Laravel";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = inputs @ {nixpkgs, ...}: let
    supportedSystems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
      };

      scripts = {
        dx = {
          exec = ''$EDITOR "$REPO_ROOT"/flake.nix'';
          description = "Edit flake.nix";
        };
        lx = {
          exec = ''$EDITOR "$REPO_ROOT"/composer.json'';
          description = "Edit composer.json";
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
      default = pkgs.mkShell {
        name = "dev";

        # Available packages on https://search.nixos.org/packages
        packages = with pkgs;
          [
            php
            composer
            phpPackages.laravel
            phpPackages.phpstan
            phpPackages.phpunit
            phpPackages.psalm
            phpPackages.xdebug
            nodejs
            yarn
          ]
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
          export REPO_ROOT=$(git rev-parse --show-toplevel)
          echo "Welcome to the laravel devshell!"
        '';
      };
    });
  };
}
