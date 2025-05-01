# Scripts for development shell
{pkgs, ...}: {
  dx = {
    exec = ''$EDITOR $REPO_ROOT/flake.nix'';
    description = "Edit the flake.nix";
  };
  lint = {
    exec = ''
      ${pkgs.statix}/bin/statix check $REPO_ROOT/flake.nix
      ${pkgs.deadnix}/bin/deadnix $REPO_ROOT/flake.nix
    '';
    description = "Run linters";
  };
}
