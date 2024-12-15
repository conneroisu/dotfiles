{
  config,
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

  environment.systemPackages = with pkgs; [
    git
    git-lfs
    gnumake
    cmake
    go-task
    vim
    stow
    unstable-pkgs.infisical

    zen-browser.packages."${system}".default
    jdk23

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
    fzf
    nerdfonts
    zellij
    gh
    docker
    atuin
    zoxide
    gum
    bat
    eza
    nixos-generators
    sleek

    nil
    nh
    rippkgs
    update-nix-fetchgit

    delta
    tailwindcss
    sad
    gcc
    llvm
    obsidian
    statix
    vhdl-ls
    nodejs
    stow
    nvc
    uv
    unzip
    htop
    ripgrep
    tealdeer
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
    go
    nodejs
    rustup
    revive
    templ
    iferr
    golines
    ruby
    zig
    gomodifytags
    elixir
    ocaml
    dune_3
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

    ## Latex
    texlab
    ltex-ls

    ## Bash
    shellcheck

    ## Java
    jdt-language-server

    ## Zig
    zls

    ## Go
    gopls
    revive
    impl
    unstable-pkgs.iferr
    golangci-lint-langserver
    golangci-lint
    templ
    gomodifytags
    gotests

    ## Python
    basedpyright

    ## Yaml
    yaml-language-server
    actionlint

    ## Svelte
    svelte-language-server

    ## Matlab
    matlab-language-server

    ## cmake
    cmake-language-server

    ## Astro
    astro-language-server

    ## Elixir
    elixir-ls
    lexical

    ## Hyprland
    hyprls

    ## Sql
    sqls

    ## VHDL
    vhdl-ls

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

    # Debuggers
    delve
  ];
}
