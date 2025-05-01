# Scripts for development shell
{pkgs, ...}: {
  dx = {
    exec = ''$EDITOR $REPO_ROOT/flake.nix'';
    description = "Edit the flake.nix";
  };
  lint = {
    exec = ''
      export REPO_ROOT=$(git rev-parse --show-toplevel)
      ${pkgs.statix}/bin/statix check $REPO_ROOT/flake.nix
      ${pkgs.deadnix}/bin/deadnix $REPO_ROOT/flake.nix
      nix flake check
    '';
    description = "Run linters";
  };
}
