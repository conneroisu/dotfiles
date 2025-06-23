{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;

  program = pkgs.writeShellScriptBin "dx" ''
    [[ -f $EDITOR ]] || EDITOR=nvim
    $EDITOR $(git rev-parse --show-toplevel)/flake.nix || echo "No toplevel file found"
  '';
in
  delib.module {
    name = "programs.dx";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      environment.systemPackages = [
        program
      ];
    };

    darwin.ifEnabled = {myconfig, ...}: {
      environment.systemPackages = [
        program
      ];
    };
  }
