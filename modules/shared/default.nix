{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  # lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  # namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  # # All other arguments come from the module system.
  # config,
  ...
}: {
  programs = {
    direnv.enable = true;
    direnv.nix-direnv.enable = true;
  };

  environment.variables = {
    NUPM_HOME = "~/dotfiles/.config/nushell/nupm/";
    EDITOR = "nvim";
    SHELL = "nu";
    GTK_THEME = "adw-gtk3-dark";
  };

  fonts.packages = with pkgs;
    [
      nerd-fonts.code-new-roman
    ]
    ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
  environment.systemPackages =
    [
      pkgs.home-manager
    ]
    ++ (with pkgs; [
      doppler
      nushell
      carapace
      devenv
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
      # Apps
      obsidian
      neovim
      emacs
      zed-editor
      vscode
      gtkwave
      inputs.zen-browser.packages."${system}".default
      inputs.nh.packages."${system}".default
      inputs.snowfall-flake.packages."${system}".default
      jetbrains.datagrip
      telegram-desktop

      # Shell
      # zsh
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

      wireguard-tools
      wireguard-ui

      rippkgs
      update-nix-fetchgit

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

      spicetify-cli
      spotify

      # Platforms
      turso-cli
      flyctl

      # Languages
      nodejs
      ruby
      rustup
      python312
      (python312.withPackages (
        ps:
          with ps; [
            numpy
            requests
            pandas
            scipy
            matplotlib
            scikitlearn
            torch
            debugpy
            opencv4
            torchvision
            selenium
            pyarrow
            psycopg
            mysqlclient
            ollama
            black
            requests
            uvicorn
            flask
            fastapi
            django
            gunicorn
            pydantic
            mypy
            torchdiffeq
            beautifulsoup4
            pillow
            gym
            pypdf
            pytest
            pip
            sympy
          ]
      ))

      # Language Servers

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
      discord
      llama-cpp
      pandoc
      google-chrome
    ]);

  # Your configuration.
}
