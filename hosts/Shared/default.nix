{
  pkgs,
  unstable-pkgs,
  zen-browser,
  ...
}: {
  programs = {
    zsh.enable = true;

    direnv.enable = true;
    direnv.nix-direnv.enable = true;
  };

  environment.variables = {
    EDITOR = "nvim";
  };

  environment.systemPackages = with pkgs; [
    git
    git-lfs
    unstable-pkgs.doppler
    zen-browser.packages."${system}".default
    gnumake
    cmake
    stow

    # Apps
    kitty
    obsidian
    neovim
    emacs
    zed-editor
    vscode

    # Shell
    zsh
    zinit
    starship
    devenv
    pkgs.direnv
    pkgs.nix-direnv
    bat
    fd
    jq
    yq
    delta
    cachix
    fzf
    nerdfonts
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

    nh
    rippkgs
    update-nix-fetchgit

    sad
    gcc
    llvm
    nodejs
    stow
    nvc
    uv
    ripgrep
    meson
    goreleaser
    sqlite
    sqlite-vec
    ollama
    jetbrains.datagrip
    pkg-config

    # Platforms
    turso-cli
    flyctl

    # Languages
    nodejs
    ruby
    rustup
    zig
    python312
    (python312.withPackages (
      ps:
        with ps; [
          numpy
          pandas
          scipy
          matplotlib
          scikitlearn
          torch
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

    ## Python
    basedpyright

    ## Yaml
    yaml-language-server
    actionlint

    ## Hyprland
    hyprls

    ## Sql
    sqls

    luajitPackages.luarocks
    wget
    pfetch-rs
    matugen
    # Formatters
    hclfmt
    shfmt
    rustfmt
    black
    tree
    alejandra
    cbfmt
    marksman

    # Debuggers
    delve
  ];
}
