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

    nixos.ifEnabled = {
      myconfig.programs = {
        dx.enable = true;
        md2pdf.enable = true;
        convert_img.enable = true;
        catls.enable = true;
        cmbd.enable = true;
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
            sqlite
            duckdb
            uv
            eza
            delta
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
            coder

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
            pkgs.jetbrains.phpstorm
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
          clean.extraArgs = "--keep-since 4d --keep 3 --extra-experimental-features nix-command --extra-experimental-features flakes";
          flake = "/home/connerohnesorge/dotfiles";
        };
      };

      security.rtkit.enable = true;
      services = {
        gnome.gnome-keyring.enable = true;
      };

      systemd = {
        # Create a separate slice for nix-daemon that is
        # memory-managed by the userspace systemd-oomd killer
        slices."nix-daemon".sliceConfig = {
          ManagedOOMMemoryPressure = "kill";
          ManagedOOMMemoryPressureLimit = "50%";
        };

        services."nix-daemon".serviceConfig = {
          Slice = "nix-daemon.slice";
          # If a kernel-level OOM event does occur anyway,
          # strongly prefer killing nix-daemon child processes
          OOMScoreAdjust = 1000;
          MemoryHigh = "5G";
          MemoryMax = "6G";
        };
      };
    };

    darwin.ifEnabled = {
      environment = {
        systemPackages = with pkgs; [
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
        ];
        variables = {
          EDITOR = "nvim";
          VISUAL = "nvim";
          GIT_EDITOR = "nvim";
        };
      };
    };
  }
