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
      myconfig.programs = {
        dx.enable = true;
        md2pdf.enable = true;
      };
      fonts.packages = with pkgs; [
        nerd-fonts.code-new-roman
        corefonts
        vistafonts
      ];
      environment = {
        systemPackages =
          (with pkgs; [
            # Shell

            ## Editor
            neovim
            jq
            yq
            tree-sitter
            sad

            ## Env
            zsh
            nushell
            carapace
            stow
            age
            nushell
            kubectl
            ktailctl
            doppler
            bun
            file
            nix-index
            zinit
            starship
            direnv
            nix-direnv
            bat
            fd
            fzf
            zellij
            atuin
            zoxide
            pkg-config
            lshw
            gdb
            gnupg
            procps
            unzip
            uv
            eza
            delta
            unzip
            htop
            tealdeer
            sleek
            unixtools.xxd
            ffmpeg
            tree
            ripgrep

            # VCS
            git
            git-lfs
            jujutsu

            # Apps
            obsidian
            zathura
            brave
            spotify
            discord
            telegram-desktop
            xfce.thunar
            obs-studio
            eog

            # Communication
            tailscale
            dnsutils
            minicom
            openvpn
            cacert
            arp-scan
            vdhcoapp
            usbutils
            ethtool
            curl
            wget

            # Platforms
            fh
            doppler
            gh
            tea

            # Emulation
            docker
            docker-compose
            lazydocker
            nixos-shell

            # Languages (Base for when shell from project is not available)
            nixd
            statix
            nodejs
            lua-language-server

            # Disks
            squirreldisk
          ])
          ++ (with inputs; [
            zen-browser.packages."${pkgs.system}".default
            blink.packages."${pkgs.system}".default
            blink.packages."${pkgs.system}".blink-fuzzy-lib
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
      };
    };
  }
