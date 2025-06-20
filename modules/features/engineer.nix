{
  delib,
  pkgs,
  inputs,
  ...
}: let
  inherit (delib) singleEnableOption;

  crossPlatformPkgs = [
    # VCS
    pkgs.git
    pkgs.git-lfs
    pkgs.jujutsu
    # Platforms
    pkgs.flyctl
    pkgs.fh
    pkgs.gh
    pkgs.tea
    # Infra
    pkgs.kubectl
    pkgs.ktailctl
    pkgs.lazydocker
  ];
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
        convert_media.enable = true;
        catls.enable = true;
        cmbd.enable = true;
        duckdb.enable = true;
        cpr.enable = true;
      };
      fonts.packages = [
        pkgs.nerd-fonts.code-new-roman
        pkgs.corefonts
        pkgs.vistafonts
      ];
      environment = {
        systemPackages = let
          stablePkgs = inputs.stable-nixpkgs.legacyPackages.${pkgs.system};
        in
          [
            inputs.opencode.packages.${pkgs.system}.default
            inputs.zen-browser.packages."${pkgs.system}".default
            inputs.blink.packages."${pkgs.system}".default
            inputs.blink.packages."${pkgs.system}".blink-fuzzy-lib
            # parcl.packages.${pkgs.system}.default
            stablePkgs.brave
            # Shell
            pkgs.libxml2
            pkgs.gcc

            ## Editor
            pkgs.neovim
            pkgs.jq
            pkgs.yq
            pkgs.tree-sitter
            pkgs.sad

            ## Env
            pkgs.zsh
            pkgs.nushell
            pkgs.carapace
            pkgs.stow
            pkgs.age
            pkgs.doppler
            pkgs.file
            pkgs.nix-index
            pkgs.zinit
            pkgs.starship
            pkgs.direnv
            pkgs.nix-direnv
            pkgs.bat
            pkgs.fd
            pkgs.fzf
            pkgs.zellij
            pkgs.atuin
            pkgs.zoxide
            pkgs.pkg-config
            pkgs.lshw
            pkgs.gdb
            pkgs.gnupg
            pkgs.procps
            pkgs.unzip
            pkgs.sqlite
            pkgs.uv
            pkgs.eza
            pkgs.delta
            pkgs.htop
            pkgs.tealdeer
            pkgs.sleek
            pkgs.unixtools.xxd
            pkgs.ffmpeg
            pkgs.tree
            pkgs.ripgrep

            pkgs.bun
            # Apps
            pkgs.obsidian
            pkgs.zathura
            pkgs.vlc
            pkgs.nemo-with-extensions
            pkgs.nemo-preview
            pkgs.nemo-fileroller

            pkgs.spotify
            pkgs.discord
            pkgs.telegram-desktop
            pkgs.obs-studio
            pkgs.eog

            # Communication
            pkgs.tailscale
            pkgs.dnsutils
            pkgs.minicom
            pkgs.openvpn
            pkgs.cacert
            pkgs.arp-scan
            pkgs.vdhcoapp
            pkgs.usbutils
            pkgs.ethtool
            pkgs.curl
            pkgs.wget

            # Platforms
            pkgs.fh
            pkgs.doppler
            pkgs.gh
            pkgs.tea

            # Emulation
            pkgs.nixos-shell
            pkgs.docker
            pkgs.docker-compose

            # Languages (Base for when shell from project is not available)
            pkgs.nixd
            pkgs.statix
            pkgs.nodejs
            pkgs.lua-language-server

            # Disks
            pkgs.squirreldisk
            pkgs.jetbrains.phpstorm
          ]
          ++ crossPlatformPkgs;
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
        envfs.enable = true;
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
          MemoryHigh = "9G";
          MemoryMax = "10G";
        };
      };
    };

    darwin.ifEnabled = {
      myconfig.programs = {
        dx.enable = true;
      };
      environment = {
        systemPackages =
          [
            pkgs.zinit
            pkgs.starship
            pkgs.direnv
            pkgs.nix-direnv
            pkgs.bat
            pkgs.wget
            pkgs.fd
            pkgs.jq
            pkgs.yq
            pkgs.spicetify-cli
            pkgs.fzf
            pkgs.zellij
            pkgs.atuin
            pkgs.zoxide
            pkgs.eza
            pkgs.delta
            pkgs.unzip
            pkgs.htop
            pkgs.tealdeer
            pkgs.sleek
            pkgs.tree-sitter
            pkgs.unixtools.xxd
            pkgs.tree
            pkgs.sad
            pkgs.ripgrep
            pkgs.stow
            pkgs.carapace
            pkgs.neovim
            pkgs.cmake
            pkgs.gnumake
            pkgs.uv
            pkgs.bun
            # Languages
            pkgs.nixd
            pkgs.nodejs
            pkgs.lua-language-server
          ]
          ++ crossPlatformPkgs;
        variables = {
          EDITOR = "nvim";
          VISUAL = "nvim";
          GIT_EDITOR = "nvim";
        };
      };
    };
  }
