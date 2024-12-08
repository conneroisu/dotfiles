{ pkgs, unstable-pkgs, ... }:

[
  pkgs.alejandra
  pkgs.nix-prefetch-git
  pkgs.nerdfonts
  pkgs.spotify
  pkgs.git
  pkgs.go-task
  pkgs.ollama
  pkgs.zsh
  pkgs.gh
  pkgs.kitty
  pkgs.docker
  pkgs.docker-compose

  # Command Line Tools
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
  pkgs.sqlite
  pkgs.wget
  pkgs.zip

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
  pkgs.gnumake
  pkgs.gcc
  pkgs.cmake
  pkgs.pkgconf
  pkgs.pkg-config

  # Languages
  pkgs.go
  pkgs.goreleaser
  pkgs.nodePackages.live-server
  pkgs.nodePackages.nodemon
  pkgs.nodePackages.prettier
  pkgs.nodePackages.npm
  pkgs.nodejs

  # Language Servers
  pkgs.lua-language-server
  pkgs.basedpyright
  pkgs.shfmt
  pkgs.nixd
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
  pkgs.golangci-lint
  pkgs.templ
  pkgs.gopls
  pkgs.gomodifytags
  pkgs.gotests
  pkgs.impl
  pkgs.docker-compose-language-service
  pkgs.shfmt
  pkgs.shellcheck
  unstable-pkgs.iferr
]
