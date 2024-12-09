{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:danth/stylix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
  };
  outputs =
    inputs@{
      self,
      ...
    }:
    let
      configuration =
        { pkgs, config, ... }:
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = with pkgs; [
            pkgs.home-manager

            # Macos Only
            aerospace
            google-chrome

            mkalias
            vim
            neovim
            zsh
            zinit
            devenv
            pkgs.direnv
            pkgs.nix-direnv
            jq
            bat
            fzf
            gh
            kitty
            docker
            zellij
            atuin
            zoxide
            nixos-generators
            emacs

            fd
            delta
            sad
            tailwindcss
            starship
            gcc
            llvm
            rustup
            obsidian
            statix
            vhdl-ls
            nodejs
            stow
            nil
            nvc
            uv
            ruby
            zig
            elixir
            ocaml
            ocamlPackages.ocaml-lsp
            dune_3
            python312
            python312Packages.numpy
            python312Packages.pandas
            python312Packages.scipy
            python312Packages.matplotlib
            python312Packages.scikitlearn
            python312Packages.torch
            python312Packages.opencv4
            python312Packages.torchvision
            python312Packages.selenium
            python312Packages.pyarrow
            python312Packages.psycopg
            python312Packages.mysqlclient
            python312Packages.ollama
            python312Packages.black
            python312Packages.requests
            python312Packages.uvicorn
            python312Packages.flask
            python312Packages.fastapi
            python312Packages.django
            python312Packages.gunicorn
            python312Packages.pydantic
            python312Packages.mypy
            python312Packages.torchdiffeq
            python312Packages.beautifulsoup4
            python312Packages.pillow
            python312Packages.gym
            python312Packages.pypdf
            python312Packages.pytest
            ripgrep
            vscode
            tealdeer
            meson

            turso-cli
            flyctl

            golangci-lint
            nil
            go
            revive
            templ
            iferr
            golines
            gomodifytags
            sqls
            sqlite
            sqlite-vec
            # Language Servers
            lua-language-server
            htmx-lsp
            texlab
            ltex-ls
            raycast
            shellcheck
            jdt-language-server
            zls
            jq-lsp
            gopls
            revive
            impl

            luajitPackages.luarocks
            wget
            nixd
            basedpyright

            nh
            # Formatters
            hclfmt
            tree
            nixfmt-rfc-style
            cbfmt
          ];

          nix.settings.experimental-features = "nix-command flakes";

          # Set Git commit hash for darwin-version.
          system = {
            configurationRevision = self.rev or self.dirtyRev or null;
            stateVersion = 5;
            defaults = {
              dock.autohide = true;

              trackpad = {
                Clicking = true;
                TrackpadThreeFingerDrag = true;
              };

            };
          };

          environment.shells = [ pkgs.zsh ];
          users.users.connerohnesorge = {
            home = "/Users/connerohnesorge";
            name = "connerohnesorge";
          };

          home-manager.users.connerohnesorge = {
            home.stateVersion = "25.05";
            home.packages = with pkgs; [
              devenv
            ];
          };
          homebrew = {
            enable = true;
            brews = [
              "goenv"
              "ollama"
              "go-task"
            ];
            casks = [
              # "ghdl"
            ];
          };
          nixpkgs.hostPlatform = "aarch64-darwin";
          security.pam.enableSudoTouchIdAuth = true;
          programs.direnv.enable = true;
          programs.direnv.nix-direnv.enable = true;
          nixpkgs.config.allowUnfree = true;
          system.activationScripts.applications.text =
            let
              env = pkgs.buildEnv {
                name = "system-applications";
                paths = config.environment.systemPackages;
                pathsToLink = "/Applications";
              };
            in
            pkgs.lib.mkForce ''
              # Set up applications.
              echo "setting up /Applications..." >&2
              rm -rf /Applications/Nix\ Apps
              mkdir -p /Applications/Nix\ Apps
              find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
              while read -r src; do
                app_name=$(basename "$src")
                echo "copying $src" >&2
                ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
              done
            '';
        };
    in
    {
      # $ darwin-rebuild build --flake .#Conners-MacBook-Air
      darwinConfigurations."Conners-MacBook-Air" = inputs.nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # home-manager.users.connerohnesorge = import ./home.nix;
          }
          inputs.nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;
              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;
              user = "connerohnesorge";
              taps = {
                "homebrew/homebrew-core" = inputs.homebrew-core;
                "homebrew/homebrew-cask" = inputs.homebrew-cask;
                "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
              };
              mutableTaps = false;
            };
          }
        ];
      };
    };
}
