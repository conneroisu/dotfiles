{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  # namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  # home, # The home architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this home (eg. `x86_64-home`).
  # format, # A normalized name for the home target (eg. `home`).
  # virtual, # A boolean to determine whether this home is a virtual target using nixos-generators.
  # host, # The host name for this home.
  # All other arguments come from the home home.
  # config,
  ...
}: {
  snowfallorg.user = {
    name = "connerohnesorge";
    enable = true;
  };

  home = {
    stateVersion = "24.05";
    packages =
      (with inputs; [
        zen-browser.packages."${system}".default
        nh.packages."${system}".default
        ghostty.packages."${system}".default
        ashell.defaultPackage.${system}
      ])
      ++ (with pkgs; [
        doppler
        nushell
        carapace
        basedpyright
        ollama
        fish
        tmux
        git
        zsh
        git-lfs
        cloc
        gnumake
        cmake
        stow
        age
        glow
        ## Nix
        nixd
        nil
        statix
        nix-index
        nix-prefetch-git

        ## Lua
        lua-language-server

        ## JSON
        jq-lsp

        ## HTMX
        htmx-lsp
        tailwindcss

        ## Latex
        texlab
        ltex-ls

        ## Bash
        shellcheck
        yaml-language-server
        actionlint
        sqls

        vscode-langservers-extracted
        luajitPackages.luarocks
        wget
        pfetch-rs

        # Formatters
        hclfmt
        shfmt
        rustfmt
        black
        tree
        alejandra
        cbfmt
        marksman
        sops
        llama-cpp
        pandoc
        ## Nix
        nixd
        nil
        statix
        nix-index
        nix-prefetch-git

        dnsutils

        sad
        gcc
        llvm
        nodejs
        stow
        nvc
        uv
        ripgrep
        meson
        sqlite
        sqlite-vec
        pkg-config
        matugen
        zinit
        starship
        pkgs.direnv
        pkgs.nix-direnv
        bat
        fd
        jq
        yq
        delta
        cachix
        fzf
        zellij
        gh
        atuin
        zoxide
        gum
        bat
        eza
        delta
        unzip
        htop
        nixos-generators
        tealdeer
        sleek
        chafa
        tree-sitter
        unixtools.xxd
        tailscale
        anki

        wireguard-tools
        wireguard-ui

        doppler
        nushell
        carapace
        basedpyright
        ollama
        fish
        tmux
        git
        zsh
        git-lfs
        cloc
        gnumake
        cmake
        stow
        age
        glow
        obsidian
        neovim
        gpu-screen-recorder
        arp-scan
        xorg.libXrandr
        zlib
        stdenv.cc
        binutils
        gitRepo
        nix-ld
        alejandra
        nh
        pipewire
        gpu-screen-recorder
        pkgs.obs-studio
        gtk3
        gtk-layer-shell
        usbutils
        yazi
        docker
        docker-compose
        docker-compose-language-service
        vdhcoapp
        qemu
        arp-scan

        # Apps
        netron
        pkgs.xfce.thunar
        vmware-horizon-client
        gimp
        pkgs.jetbrains.rust-rover
        pkgs.libnotify

        openvpn
        cacert

        ghdl
        nvc
        lshw
        pkgconf
        gdb
        gnupg
        autoconf
        curl
        procps
        gnumake
        util-linux
        unzip
        libGLU
        libGL
        xorg.libXi
        xorg.libXmu
        freeglut
        xorg.libXext
        xorg.libX11
        xorg.libXv
      ]);
  };
  nix.enable = pkgs.lib.mkDefault false;

  programs = {
    home-manager = {
      enable = true;
    };
  };

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyodark.yaml";
    image = ./../../../assets/klaus-desktop.jpeg;
    polarity = "dark";
    targets.rofi.enable = true;
    targets.kitty.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = lib.mkForce "adw-gtk3-dark";
      package = lib.mkForce pkgs.adw-gtk3;
    };
    iconTheme.package = pkgs.papirus-icon-theme;
    iconTheme.name = "Papirus";

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  qt = {
    enable = true;
    platformTheme.name = pkgs.lib.mkDefault "adwaita";
    style.name = pkgs.lib.mkDefault "adwaita-dark";
    style.package = pkgs.adwaita-qt;
  };
}
