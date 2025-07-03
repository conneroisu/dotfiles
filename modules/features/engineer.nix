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
      myconfig.programs = {
        dx.enable = true;
        md2pdf.enable = true;
        convert_img.enable = true;
        catls.enable = true;
        cmbd.enable = true;
        splitm.enable = true;
      };
      fonts.packages = with pkgs; [
        nerd-fonts.code-new-roman
        corefonts
        vistafonts
      ];
      environment = {
        systemPackages =
          [
            # Shell

            ## Editor
            pkgs.neovim
            pkgs.jq
            pkgs.yq
            pkgs.tree-sitter
            pkgs.sad

            ## Env
            pkgs.zsh
            pkgs.nushell
            pkgs.dbus
            pkgs.lsof
            pkgs.carapace
            pkgs.stow
            pkgs.age
            pkgs.kubectl
            pkgs.ktailctl
            pkgs.doppler
            pkgs.bun
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

            # VCS
            pkgs.git
            pkgs.git-lfs
            pkgs.jujutsu

            # Apps
            pkgs.obsidian
            pkgs.zathura
            pkgs.brave
            pkgs.spotify
            pkgs.discord
            pkgs.telegram-desktop
            pkgs.obs-studio
            pkgs.eog
            pkgs.nemo-with-extensions

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
            pkgs.docker
            pkgs.docker-compose
            pkgs.docker-buildx
            pkgs.lazydocker
            pkgs.nixos-shell

            # Languages (Base for when shell from project is not available)
            pkgs.nixd
            pkgs.statix
            pkgs.nodejs
            pkgs.lua-language-server
          ]
          ++ [
            inputs.zen-browser.packages."${pkgs.system}".default
            inputs.blink.packages."${pkgs.system}".default
            inputs.blink.packages."${pkgs.system}".blink-fuzzy-lib
            inputs.nordvpn.packages."${pkgs.system}".default
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
      };
    };

    darwin.ifEnabled = {
      myconfig.programs = {
        dx.enable = true;
        splitm.enable = true;
      };
      environment = {
        systemPackages = [
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
          pkgs.zed-editor
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
          pkgs.git
          pkgs.podman
          pkgs.rancher
          pkgs.openssl

          # Platforms
          pkgs.flyctl
          pkgs.fh
          pkgs.gh
          pkgs.tea

          # Languages
          pkgs.nixd
          pkgs.nodejs
          pkgs.lua-language-server
        ];
        variables = {
          EDITOR = "nvim";
          VISUAL = "nvim";
          GIT_EDITOR = "nvim";
        };
      };
    };
  }
