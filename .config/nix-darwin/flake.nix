{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
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
      nix-darwin,
      nixpkgs,
      home-manager,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      homebrew-bundle,
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
            vhdl-ls
            nodejs
            stow
            nil
            nvc
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
            shellcheck
            jdt-language-server
            zls
            jq-lsp
            luajitPackages.luarocks
            wget
            # python312Packages.basedpyright # TODO: add to nixpkgs

            # Formatters
            hclfmt
            nixfmt-rfc-style
            cbfmt
          ];

          nix.settings.experimental-features = "nix-command flakes";

          # programs.zsh.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          environment.shells = [ pkgs.zsh ];
          users.users.connerohnesorge = {
            home = "/Users/connerohnesorge";
            name = "connerohnesorge";
          };

          home-manager.users.connerohnesorge = {
            home.stateVersion = "25.05";
            home.packages =
              with pkgs;
              [
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

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
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
      darwinConfigurations."Conners-MacBook-Air" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # home-manager.users.connerohnesorge = import ./home.nix;
          }
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;
              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;
              user = "connerohnesorge";
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-bundle" = homebrew-bundle;
              };
              mutableTaps = false;
            };
          }
        ];
      };
    };
}
