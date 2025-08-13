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
        php = pkgs.php82; # Updated to php82 for compatibility with Satis requirements
      };
    in {
      devShells.default = pkgs.mkShellNoCC {
        name = "php-devshell";
        buildInputs = [
          php
          php.packages.composer
          php.packages.phpstan
          # php.packages.psalm # Temporarily disabled as it's marked broken in current nixpkgs
          pkgs.phpunit
          self.packages.${system}.satis
        ];
      };

      checks = {
        inherit (self.packages.${system}) drupal satis symfony-demo;
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
        drupal = php.buildComposerProject {
          pname = "drupal";
          version = "11.0.0-dev";
          src = pkgs.fetchFromGitHub {
            owner = "drupal";
            repo = "drupal";
            rev = "967e3af639f380d7524c1551ac207339cb16eaa4";
            hash = "sha256-88Lks6DGaiHvt4561PCfbg9brcW7OQQmBiPFOUeaq6Y=";
          };
          vendorHash = "sha256-39cCLG4x8/C9XZG2sOCpxO1HUsqt3DduCMMIxPCursw=";
        };
        symfony-demo-image = pkgs.dockerTools.buildLayeredImage {
          name = self.packages.${system}.symfony-demo.pname;
          tag = "latest";
          contents = let
            caddyFile = pkgs.writeText "Caddyfile" ''
              {
                  email youremail@domain.com
              }
              :80 {
                  root * /app/public
                  log
                  encode gzip
                  php_fastcgi 127.0.0.1:9000
                  file_server
              }
              :443 {
                  root * /app/public
                  log
                  encode gzip
                  php_fastcgi 127.0.0.1:9000
                  file_server
                  tls internal {
                      on_demand
                  }
              }
            '';
          in [
            php
            pkgs.caddy
            pkgs.fakeNss
            (pkgs.writeScriptBin "start-server" ''
              #!${pkgs.runtimeShell}
              php-fpm -D -y /etc/php-fpm.d/www.conf.default
              caddy run --adapter caddyfile --config ${caddyFile}
            '')
          ];
          extraCommands = ''
            ln -s ${self.packages.${system}.symfony-demo}/share/php/${self.packages.${system}.symfony-demo.pname}/ app
            mkdir -p tmp
            chmod -R 777 tmp
            cp ${self.packages.${system}.symfony-demo}/share/php/${self.packages.${system}.symfony-demo.pname}/data/database.sqlite tmp/database.sqlite
            chmod +w tmp/database.sqlite
          '';
          config = {
            Cmd = ["start-server"];
            ExposedPorts = {
              "80/tcp" = {};
              "443/tcp" = {};
            };
          };
        };
        symfony-demo = php.buildComposerProject {
          pname = "symfony-demo";
          version = "1.0.0";
          src = pkgs.fetchFromGitHub {
            owner = "symfony";
            repo = "demo";
            rev = "143bba24480ad28e911c18e879a1d17623b447fb";
            hash = "sha256-8VJyidkuU/JKNES58NtPHNpOLR6iGGsFp6VaDozoRe0=";
          };
          composerNoDev = false;
          composerNoPlugins = false;
          preInstall = ''
            ls -la
          '';
          vendorHash = "sha256-Nv9pRQJ2Iij1IxPNcCk732Q79FWB/ARJRvjPVVyLMEc=";
        };
      };

      apps = let
        lib = pkgs.lib;
      in {
        mezzio-skeleton = {
          type = "app";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "mezzio-skeleton-demo";
              runtimeInputs = [php];
              text = ''
                ${lib.getExe php} -S 0.0.0.0:8080 -t ${self.packages.${system}.mezzio}/share/php/${self.packages.${system}.mezzio.pname}/public/
              '';
            }
          );
        };
        symfony-demo = {
          type = "app";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "php-symfony-demo";
              runtimeInputs = [php];
              text = ''
                APP_CACHE_DIR=$(mktemp -u)/cache
                APP_LOG_DIR=$APP_CACHE_DIR/log
                DATABASE_URL=sqlite:///$APP_CACHE_DIR/database.sqlite
                export APP_CACHE_DIR
                export APP_LOG_DIR
                export DATABASE_URL
                mkdir -p "$APP_CACHE_DIR"
                mkdir -p "$APP_LOG_DIR"
                cp -f ${self.packages.${system}.symfony-demo}/share/php/symfony-demo/data/database.sqlite "$APP_CACHE_DIR"/database.sqlite
                chmod +w "$APP_CACHE_DIR"/database.sqlite
                ${lib.getExe pkgs.symfony-cli} serve --document-root ${self.packages.${system}.symfony-demo}/share/php/symfony-demo/public --allow-http
              '';
            }
          );
        };
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
        # nix run .#psalm -- --version
        # psalm = {
        #   type = "app";
        #   program = lib.getExe (
        #     pkgs.writeShellApplication {
        #       name = "psalm";
        #       runtimeInputs = [
        #         php
        #         php.packages.psalm
        #       ];
        #       text = ''
        #         ${lib.getExe php.packages.psalm} "$@"
        #       '';
        #     }
        #   );
        # }; # Temporarily disabled as psalm is marked broken in current nixpkgs
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
