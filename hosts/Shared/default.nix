{
  pkgs,
  unstable-pkgs,
  agenix,
  ...
}: {
  environment.systemPackages = with pkgs; [
    git
    git-lfs
    pkgs.home-manager
    gnumake
    cmake
    go-task
    vim
    obsidian
    stow
    infisical
    agenix.packages.${system}.default

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
    kitty
    zellij
    gh
    docker
    atuin
    zoxide
    gum
    bat
    eza
    nixos-generators
    emacs

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
    nil
    nvc
    uv
    unzip
    ripgrep
    tealdeer
    meson
    goreleaser
    sqlite
    sqlite-vec
    ollama

    # Editors
    neovim
    zed-editor
    vscode

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
