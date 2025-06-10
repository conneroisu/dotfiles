{
  delib,
  # inputs,
  # system,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "programs.proton-x";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [
        pkgs.protonmail-desktop
        pkgs.proton-pass
      ];
    };
    darwin.ifEnabled = {
      # TODO: maybe use homebrew
      # environment.systemPackages = [
      # ];
    };
  }
