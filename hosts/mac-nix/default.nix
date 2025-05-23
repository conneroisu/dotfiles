{
  delib,
  inputs,
  pkgs,
  config,
  ...
}: let
  system = "aarch64-darwin";
in
  delib.host {
    name = "Conners-MacBook-Air";
    rice = "dark";
    type = "laptop";

    home.home.stateVersion = "24.11";
    homeManagerSystem = system;

    myconfig = {
      programs = {
        catls.enable = true;
        convert_img.enable = true;
      };
    };

    darwin = {
      nixpkgs = {
        hostPlatform = system;
        config.allowUnfree = true;
      };
      nix.enable = false;
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs;
        [
          # Macos Only
          aerospace
          raycast
          xcodes
          # Shared
          # TODO: Share
          zinit
          starship
          direnv
          nix-direnv
          bat
          wget
          fd
          jq
          yq
          spicetify-cli
          fzf
          zellij
          atuin
          zoxide
          eza
          delta
          unzip
          htop
          tealdeer
          sleek
          tree-sitter
          unixtools.xxd
          tree
          sad
          ripgrep
          stow
          carapace
          neovim
          cmake
          gnumake
          uv
          bun
          git
          # Platforms
          flyctl
          fh
          gh
          tea

          # Languages
          nixd
          nodejs
          lua-language-server
        ]
        ++ (with inputs; [
          blink.packages."${system}".default
          blink.packages."${system}".blink-fuzzy-lib
        ]);
      programs = {
        direnv.enable = true;
        direnv.nix-direnv.enable = true;
        ssh = {
          extraConfig = ''
            SetEnv TERM=xterm-256color
          '';
        };
      };
      system = {
        stateVersion = 5;
        defaults = {
          dock.autohide = true;

          trackpad = {
            Clicking = true;
            TrackpadThreeFingerDrag = true;
            Dragging = true;
          };
        };
      };

      environment.shells = [pkgs.zsh];
      users.users.connerohnesorge = {
        home = "/Users/connerohnesorge";
      };

      security.pam.services.sudo_local.touchIdAuth = true;
      system.activationScripts.applications.text = let
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
  }
