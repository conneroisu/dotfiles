{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "programs.dx";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "dx" ''
            $EDITOR $(git rev-parse --show-toplevel)/flake.nix'')
      ];
    };

    darwin.ifEnabled = {myconfig, ...}: {
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "dx" ''
            $EDITOR $(git rev-parse --show-toplevel)/flake.nix'')
      ];
    };
  }
