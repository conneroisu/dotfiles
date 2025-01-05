{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  name = "dotfiles";

  languages = {
    nix.enable = true;
  };

  packages = with pkgs; [
    git
    sqldiff
    pprof
    podman
    revive
    iferr
    impl
    golangci-lint
    golangci-lint-langserver
    gopls
    gomodifytags
    gomarkdoc
    gotests
    gotools
    templ
    sqlc
    flyctl
    air
    wireguard-tools
  ];

  scripts = {
    latest.exec = ''
      cd $(git rev-parse --show-toplevel) && git add . && git commit -m "latest" && git push
    '';
    dx.exec = ''$EDITOR $(git rev-parse --show-toplevel)/devenv.nix'';
  };

  enterShell = ''git status'';
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  cachix.enable = true;
}
