{
  lib,
  pkgs,
  inputs,
  system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  config,
  ...
}:
{
  programs = {
    direnv.enable = true;
    direnv.nix-direnv.enable = true;
  };

  environment = {
    etc."nix/nix.custom.conf".text =
      let
        # This function converts an attribute set to Nix configuration lines
        settingsToConf =
          settings:
          lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              name: value:
              "${name} = ${
                if builtins.isBool value then
                  lib.boolToString value
                else if builtins.isInt value then
                  toString value
                else if builtins.isList value then
                  lib.concatMapStringsSep " " (x: "${toString x}") value
                else if builtins.isString value then
                  value
                else
                  throw "Unsupported type for nix.conf setting ${name}"
              }"
            ) settings
          );
      in
      # Apply the function to your desired settings
      settingsToConf {
        # Add your nix settings here, for example:
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          "@wheel"
          "connerohnesorge"
        ];
        allowed-users = [
          "root"
          "@wheel"
          "connerohnesorge"
        ];
      };

    variables = {
      NUPM_HOME = "~/dotfiles/.config/nushell/nupm/";
      EDITOR = "nvim";
      SHELL = "nu";
      GTK_THEME = "adw-gtk3-dark";
    };

    systemPackages =
      let
        python-venv = pkgs.python312.withPackages (
          ps: with ps; [
            numpy
            requests
            pandas
            scipy
            matplotlib
            huggingface-hub
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
        );
      in
      [
        pkgs.home-manager
      ]
      ++ (with pkgs; [
        doppler
        bun
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

        # Apps
        obsidian
        neovim
        vscode
        gtkwave
        inputs.zen-browser.packages."${system}".default
        inputs.nh.packages."${system}".default
        inputs.snowfall-flake.packages."${system}".default
        jetbrains.datagrip
        telegram-desktop
        google-chrome
        brave

        # Shell
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
        fh
        gh
        minicom

        # Languages
        nodejs
        ruby
        rustup
        python-venv

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
        nix-search-cli
        ffmpeg

        (pkgs.writeShellScriptBin "clean_png" ''
          ${python-venv}/bin/python ${./clean_png.py} $1
        '')
        (pkgs.writeShellScriptBin "convert_img" ''
          ${python-venv}/bin/python ${./convert_img.py} $1 $2
        '')
        (pkgs.writeShellScriptBin "catls" (builtins.readFile ./catls.sh))
      ]);
  };

  fonts.packages =
    with pkgs;
    [
      nerd-fonts.code-new-roman
      corefonts
      vistafonts
    ]
    ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
}
