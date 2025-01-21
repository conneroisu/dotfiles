{
  pkgs,
  # lib,
  # config,
  # inputs,
  ...
}: {
  name = "dotfiles";

  languages = {
    nix.enable = true;
  };

  git-hooks = {
    hooks = {
      alejandra.enable = true;
      deadnix.enable = true;
    };
  };

  packages = with pkgs; [
    git
    podman
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
