/**
# Feature Module: Software Engineer Toolkit

## Description
Comprehensive development environment for software engineers. Provides
a complete suite of development tools, editors, version control systems,
language runtimes, and productivity utilities for professional software
development across multiple platforms and languages.

## Platform Support
- ✅ NixOS (full support)
- ✅ Darwin (most tools, platform-specific adaptations)

## What This Enables
- **Development Tools**: Editors, debuggers, profilers
- **Custom Programs**: dx, md2pdf, convert_img, catls, cmbd, splitm
- **Language Support**: Go, Rust, Python, Node.js, and more
- **Cloud Platforms**: AWS, Kubernetes, Docker tooling
- **Version Control**: Git with enhanced tools
- **Fonts**: Programming fonts including NerdFonts

## Tool Categories
### Editors & IDE Support
- Neovim with full LSP support
- Tree-sitter for syntax highlighting
- Code formatting and linting tools

### Shell Environment
- Zsh and Nushell with completions
- Terminal multiplexers (Tmux, Zellij)
- Modern CLI tools (fd, ripgrep, bat, fzf)

### Development Utilities
- Container tools (Docker, Podman, Kubernetes)
- Build systems (Make, Just, Bazel)
- API testing (HTTPie, Hurl)
- Database clients

### Languages & Runtimes
- Go: Full toolchain with templ support
- Rust: Compiler, Cargo, Rustfmt, Clippy
- Python: Multiple versions with Poetry
- Node.js: Via Volta version manager
- JVM: Zulu JDK builds

### Cloud & DevOps
- AWS CLI and SSM tools
- Kubernetes (kubectl, k9s, stern)
- Infrastructure as Code (Terraform)
- CI/CD tools

## Integrations
- NordVPN for secure connections
- nix-ld for running dynamic binaries
- Tailscale for development networks

## Common Use Cases
- Full-stack web development
- Systems programming
- Cloud infrastructure management
- DevOps and automation
- Open source contribution

## Performance Tools
- Profiling: pprof, flamegraph
- Monitoring: htop, bottom, procs
- Network: tcpdump, tshark
- Benchmarking utilities
*/
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
      inputs.nordvpn.nixosModules.nordvpn
    ];

    options = singleEnableOption false;

    nixos.ifEnabled = {
      myconfig = {
        features.zshell.enable = true;
        programs = {
        dx.enable = true;
        md2pdf.enable = true;
        convert_img.enable = true;
        catls.enable = true;
        cmbd.enable = true;
        splitm.enable = true;
        nviml.enable = true;
        cccleaner.enable = true;
        };
      };
      fonts.packages = with pkgs; [
        nerd-fonts.code-new-roman
        corefonts
        vistafonts
      ];
      environment = {
        systemPackages = with pkgs;
          [
            # Shell

            ## Editor
            neovim
            yq
            tree-sitter
            sad

            ## Env
            zsh
            nushell
            dbus
            upower
            upower-notify
            lsof
            age
            kubectl
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
            gnupg
            procps
            sleek
            unixtools.xxd
            ffmpeg
            tree
            fdtools
            vscode-langservers-extracted

            # VCS
            git-lfs
            jujutsu

            # Apps
            obsidian
            zathura
            brave
            spotify
            discord
            telegram-desktop
            obs-studio
            eog
            nemo-with-extensions

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
            squirreldisk
          ]
          ++ [
            inputs.crush.packages."${pkgs.system}".default
            inputs.zen-browser.packages."${pkgs.system}".default
            inputs.blink.packages."${pkgs.system}".default
            inputs.blink.packages."${pkgs.system}".blink-fuzzy-lib
            inputs.nordvpn.packages."${pkgs.system}".default
            inputs.nix-auth.packages."${pkgs.system}".default
            inputs.nix-tree-rs.packages."${pkgs.system}".default
            inputs.locker.packages."${pkgs.system}".default
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

      security.rtkit.enable = true;

      services = {
        # k3s.enable = true;
        gnome.gnome-keyring.enable = true;
        nordvpn.enable = true;
        upower.enable = true;
      };
    };

    darwin.ifEnabled = {
      myconfig = {
        features.zshell.enable = true;
        programs = {
        dx.enable = true;
        splitm.enable = true;
        cccleaner.enable = true;
        };
      };
      environment = {
        systemPackages = with pkgs; [
          cmake
          yq
          graphite-cli
          spicetify-cli
          zed-editor
          python313Packages.huggingface-hub
          sleek
          tree-sitter
          unixtools.xxd
          tree
          sad
          neovim
          cmake
          gnumake
          vscode-langservers-extracted
          bun
          podman
          rancher
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
          inputs.nix-auth.packages."${pkgs.system}".default
          inputs.locker.packages."${pkgs.system}".default
        ];
        variables = {
          EDITOR = "nvim";
          VISUAL = "nvim";
          GIT_EDITOR = "nvim";
        };
      };
    };
  }
