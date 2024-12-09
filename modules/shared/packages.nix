{
  inputs,
  pkgs,
  unstable-pkgs,
  ...
}:

[
  pkgs.home-manager
  pkgs.nerdfonts
  pkgs.spotify
  pkgs.ollama
  pkgs.kitty
  pkgs.docker
  pkgs.docker-compose
  pkgs.sqlite
  pkgs.sqlite-vec
  pkgs.coreutils
  pkgs.unrar
  pkgs.unzip
  pkgs.age
  pkgs.age-plugin-yubikey
  # Web
  pkgs.wget
  pkgs.zip
  pkgs.cachix

  # Shells
  pkgs.zsh

  # Command Line Tools
  pkgs.git
  pkgs.nix-prefetch-git
  pkgs.htop
  pkgs.gum
  pkgs.stow
  pkgs.starship
  pkgs.ripgrep
  pkgs.tree
  pkgs.bat
  pkgs.fzf
  pkgs.fd
  pkgs.sad
  pkgs.delta
  pkgs.jq
  pkgs.atuin
  pkgs.zoxide
  pkgs.zellij
  pkgs.eza
  pkgs.uv
  pkgs.tailwindcss
  pkgs.tealdeer

  # Editors
  pkgs.neovim
  pkgs.zed-editor
  pkgs.obsidian
  pkgs.emacs

  # Debuggers
  pkgs.delve
  pkgs.gdb

  # Platforms
  pkgs.turso-cli
  pkgs.flyctl
  pkgs.gh

  # Build Tools
  pkgs.llvm
  pkgs.gnumake
  pkgs.go-task
  pkgs.gcc
  pkgs.cmake
  pkgs.pkgconf
  pkgs.pkg-config
  pkgs.meson
  pkgs.nvc

  # Languages
  pkgs.go
  pkgs.goreleaser
  pkgs.rustup
  pkgs.nodePackages.live-server
  pkgs.nodePackages.nodemon
  pkgs.nodePackages.prettier
  pkgs.nodePackages.npm
  pkgs.bun
  pkgs.nodejs
  pkgs.ocaml
  pkgs.dune_3
  pkgs.zig
  pkgs.ruby
  pkgs.elixir
  pkgs.luajitPackages.luarocks

  # Language Servers
  pkgs.templ
  pkgs.elixir-ls
  pkgs.zls
  pkgs.rubyfmt
  pkgs.ruby-lsp
  pkgs.ocamlPackages.ocaml-lsp
  pkgs.lua-language-server
  pkgs.basedpyright
  pkgs.shfmt
  pkgs.nixd
  pkgs.alejandra
  pkgs.statix
  pkgs.ocamlPackages.ocaml-lsp
  pkgs.shellcheck
  pkgs.vhdl-ls
  pkgs.ltex-ls
  pkgs.hyprls
  pkgs.zls
  pkgs.sqls
  pkgs.yaml-language-server
  pkgs.svelte-language-server
  pkgs.matlab-language-server
  pkgs.cmake-language-server
  pkgs.astro-language-server
  pkgs.jdt-language-server
  pkgs.lexical
  pkgs.actionlint
  pkgs.verible
  pkgs.revive
  pkgs.golangci-lint-langserver
  pkgs.reftools
  pkgs.golangci-lint
  pkgs.templ
  pkgs.gopls
  pkgs.cobra-cli
  pkgs.gomodifytags
  pkgs.gotests
  pkgs.impl
  pkgs.docker-compose-language-service
  pkgs.shfmt
  pkgs.shellcheck
  pkgs.jdt-language-server
  pkgs.cbfmt
  unstable-pkgs.iferr
]
