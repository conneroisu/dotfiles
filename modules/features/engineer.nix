{
  delib,
  pkgs,
  inputs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.engineer";

    nixos.always.imports = [
      inputs.nix-ld.nixosModules.nix-ld
    ];

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      fonts.packages = with pkgs; [
        nerd-fonts.code-new-roman
        corefonts
        vistafonts
      ];
      environment = {
        systemPackages =
          (with pkgs; [
            kubectl
            doppler
            pandoc
            bun
            ollama
            git
            zsh
            nushell
            carapace
            git-lfs
            stow
            age
            nushell
            coder
            nix-index
            file
            # Apps
            obsidian
            neovim
            brave
            spotify
            discord
            telegram-desktop
            xfce.thunar
            # Shell
            zinit
            starship
            direnv
            nix-direnv
            bat
            wget
            fd
            jq
            yq
            tree-sitter
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
            unixtools.xxd
            ffmpeg
            tree
            uv
            sad
            ripgrep
            pkg-config
            lshw
            gdb
            gnupg
            curl
            procps
            unzip
            # Communication
            tailscale
            dnsutils
            minicom
            openvpn
            cacert
            arp-scan
            vdhcoapp
            usbutils
            obs-studio
            # Platforms
            fh
            doppler
            gh
            tea
            # Emulation
            docker
            docker-compose
            # Languages
            nixd
            statix
            nodejs
            lua-language-server
          ])
          ++ (with inputs; [
            zen-browser.packages."${pkgs.system}".default
            blink.packages."${pkgs.system}".default
            blink.packages."${pkgs.system}".blink-fuzzy-lib
            zed.packages."${pkgs.system}".default
          ]);
        variables = {
          EDITOR = "nvim";
          VISUAL = "nvim";
          GIT_EDITOR = "nvim";
        };
      };

      programs = {
        nix-ld.dev.enable = true;
        direnv.enable = true;
        direnv.nix-direnv.enable = true;
        ssh = {
          extraConfig = ''
            SetEnv TERM=xterm-256color
          '';
        };
        zsh.enable = true;
        ssh = {
          askPassword = pkgs.lib.mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
        };
        nh = {
          enable = true;
          package = pkgs.nh;
          clean.enable = true;
          clean.extraArgs = "--keep-since 4d --keep 3";
          flake = "/home/connerohnesorge/dotfiles";
        };
      };

      security.rtkit.enable = true;
      services = {
        gnome.gnome-keyring.enable = true;
        ollama = {
          enable = true;
          package = pkgs.ollama;
          acceleration = "cuda";
        };
      };
    };
  }
