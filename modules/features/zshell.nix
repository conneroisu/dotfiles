{
  delib,
  pkgs,
  inputs,
  ...
}: let
  inherit (delib) singleEnableOption;

  systemPackages = with pkgs; [
    zinit
    starship
    direnv
    nix-direnv
    bat
    wget
    fd
    jq
    fzf
    zellij
    atuin
    zoxide
    eza
    delta
    unzip
    htop
    tealdeer
    ripgrep
    stow
    carapace
    uv
    git
  ];
in
  delib.module {
    name = "features.zshell";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment = {
        inherit systemPackages;
      };
    };

    darwin.ifEnabled = {
      environment = {
        inherit systemPackages;
      };
    };
  }
