{
  description = "Example flake for PHP development";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-shell.url = "github:loophp/nix-shell";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs @ {
    self,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [inputs.nix-shell.overlays.default];
        config.allowUnfree = true;
      };

      php = pkgs.api.buildPhpFromComposer {
        src = inputs.self;
        php = pkgs.php84; # Updated to php84 for latest features and compatibility
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
        cx = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/composer.json'';
          description = "Edit composer.json";
        };
        ax = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/artisan'';
          description = "Edit artisan";
        };
        lx = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/.env'';
          description = "Edit .env file";
        };
        lint = {
          exec = rooted ''cd "$REPO_ROOT" && ./vendor/bin/pint'';
          description = "Run Laravel Pint linting";
        };
        tests = {
          exec = rooted ''cd "$REPO_ROOT" && ./vendor/bin/pest'';
          description = "Run Pest tests";
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
      devShells.default = pkgs.mkShellNoCC {
        name = "php-devshell";
        buildInputs =
          [
            php
            php.packages.composer
            php.packages.phpstan
            pkgs.phpunit
            pkgs.laravel
            self.packages.${system}.satis
          ]
          ++ builtins.attrValues scriptPackages;
      };

      checks = {
        inherit (self.packages.${system}) satis;
      };

      packages = {
        satis = php.buildComposerProject {
          pname = "satis";
          version = "3.0.0-dev";
          src = pkgs.fetchFromGitHub {
            owner = "composer";
            repo = "satis";
            rev = "5c2456800f331d2895996bb681fd96acafe5f031";
            hash = "sha256-BYNpJpzBN6iBpesvdrgvpyYs0+MjhmKzDEz5CUH7xlI=";
          };
          vendorHash = "sha256-SpKS2GLxh829MceZTsmOBAZikDkARHg1koKk9cUazxM=";
          meta.mainProgram = "satis";
        };
      };

      apps = let
        lib = pkgs.lib;
      in {
        # mezzio-skeleton = {
        #   type = "app";
        #   program = lib.getExe (
        #     pkgs.writeShellApplication {
        #       name = "mezzio-skeleton-demo";
        #       runtimeInputs = [php];
        #       text = ''
        #         ${lib.getExe php} -S 0.0.0.0:8080 -t ${self.packages.${system}.mezzio}/share/php/${self.packages.${system}.mezzio.pname}/public/
        #       '';
        #     }
        #   );
        # }; # Disabled - mezzio package not defined
        # nix run .#satis -- --version
        satis = {
          type = "app";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "satis";
              text = ''
                ${lib.getExe self.packages.${system}.satis} "$@"
              '';
            }
          );
        };
        # nix run .#composer -- --version
        composer = {
          type = "app";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "composer";
              runtimeInputs = [
                php
                php.packages.composer
              ];
              text = ''
                ${lib.getExe php.packages.composer} "$@"
              '';
            }
          );
        };
        # nix run .#grumphp -- --version
        grumphp = {
          type = "app";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "grumphp";
              runtimeInputs = [php];
              text = ''
                ${lib.getExe php.packages.grumphp} "$@"
              '';
            }
          );
        };
        # nix run .#phpunit -- --version
        phpunit = {
          type = "app";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "phpunit";
              runtimeInputs = [php];
              text = ''
                ${lib.getExe pkgs.phpunit} "$@"
              '';
            }
          );
        };
        # nix run .#phpstan -- --version
        phpstan = {
          type = "app";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "phpstan";
              runtimeInputs = [
                php
                php.packages.phpstan
              ];
              text = ''
                ${lib.getExe php.packages.phpstan} "$@"
              '';
            }
          );
        };
      };

      formatter = let
        treefmtModule = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true; # Nix formatter
          };
        };
      in
        inputs.treefmt-nix.lib.mkWrapper pkgs treefmtModule;
    });
}
