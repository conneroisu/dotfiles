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
      inputs.nordvpn.nixosModules.default
      {
        services.nordvpn = {
          enable = true;
          users = ["connerohnesorge"]; # Users to add to nordvpn group
        };
      }
    ];

    options = singleEnableOption false;

    nixos.ifEnabled = {
      myconfig = {
        features = {
          zshell.enable = true;
        };
        programs = {
          # pdf2md.enable = true;
          xlaude.enable = true;
          zlaude.enable = true;
          klaude.enable = true;
          ghostty.enable = true;
          dx.enable = true;
          convert_img.enable = true;
          catls.enable = true;
          cf.enable = true;
          cmbd.enable = true;
          nviml.enable = true;
        };
      };
      fonts.packages = with pkgs; [
        nerd-fonts.code-new-roman
        corefonts
        vista-fonts
      ];
      documentation = {
        enable = true;
        dev.enable = true;
        nixos.enable = true;
        man.enable = true;
      };
      environment = {
        systemPackages = with pkgs;
          [
            ## Env
            nushell
            dbus
            upower
            upower-notify
            age
            kubectl
            nerdctl
            ktailctl
            doppler
            bun
            file
            nix-index
            vscode-langservers-extracted
            yaml-language-server
            gcc
            pkg-config
            lshw
            gdb
            gotestsum
            luarocks
            gnupg
            procps
            sleek
            unixtools.xxd
            ffmpeg
            tree
            fdtools
            stdenv.cc
            xdg-utils
            zip
            glibc.dev
            man-pages
            man-pages-posix
            man-db
            wezterm

            # VCS
            git-lfs
            jujutsu

            # Apps
            obsidian
            brave
            spotify
            evince
            discord
            telegram-desktop
            obs-studio
            eog
            nemo-with-extensions
            google-chrome
            strace
            altus
            vlc

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
            gimp

            # Platforms
            fh
            doppler
            gh
            tea

            # Emulation
            docker
            docker-compose
            docker-buildx
            lazydocker
            nixos-shell

            # Languages (Base for when shell from project is not available)
            nixd
            statix
            nodejs
            lua-language-server
            zed-editor
          ]
          ++ [
            inputs.kiro-flake.packages."${pkgs.stdenv.hostPlatform.system}".default
            inputs.conclaude.packages."${pkgs.stdenv.hostPlatform.system}".default
            inputs.nix-ai-tools.packages."${pkgs.stdenv.hostPlatform.system}".crush
            inputs.nordvpn.packages."${pkgs.stdenv.hostPlatform.system}".default
            inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
            inputs.blink.packages."${pkgs.stdenv.hostPlatform.system}".default
            inputs.blink.packages."${pkgs.stdenv.hostPlatform.system}".blink-fuzzy-lib
            inputs.nix-auth.packages."${pkgs.stdenv.hostPlatform.system}".default
            inputs.nix-version-search.packages."${pkgs.stdenv.hostPlatform.system}".default
            inputs.spectr.packages."${pkgs.stdenv.hostPlatform.system}".default
          ];
        variables = {
          EDITOR = "nvim";
          VISUAL = "nvim";
          GIT_EDITOR = "nvim";
        };
      };

      programs = {
        tmux.enable = true;
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

      virtualisation = {
        docker = {
          enable = true;
          extraPackages = [pkgs.docker-buildx];
        };
        containerd = {
          enable = true;
        };
      };

      security.rtkit.enable = true;
    };

    darwin.ifEnabled = {
      myconfig = {
        features.zshell.enable = true;
        programs = {
          dx.enable = true;
          cf.enable = true;
          ghostty.enable = true;
          zlaude.enable = true;
          klaude.enable = true;
        };
      };
      environment = {
        systemPackages = with pkgs; [
          spicetify-cli
          python313Packages.huggingface-hub
          sleek
          tree-sitter
          unixtools.xxd
          tree
          sad
          gnumake
          vscode-langservers-extracted
          bun
          podman
          openssl

          # Platforms
          flyctl
          fh
          gh
          tea

          # Languages
          nixd
          nodejs
          lua-language-server

          # Nix tools
          inputs.nix-auth.packages."${pkgs.stdenv.hostPlatform.system}".default
          inputs.nix-ai-tools.packages."${pkgs.stdenv.hostPlatform.system}".crush
          inputs.conclaude.packages."${pkgs.stdenv.hostPlatform.system}".default
        ];
        variables = {
          EDITOR = "nvim";
          VISUAL = "nvim";
          GIT_EDITOR = "nvim";
        };
      };
    };
  }
