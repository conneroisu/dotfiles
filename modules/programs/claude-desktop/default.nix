{
  delib,
  inputs,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "programs.claude-desktop";
    options = singleEnableOption false;
    nixos.ifEnabled = {
      environment.systemPackages = [
        inputs.claude-desktop.packages.${pkgs.system}.claude-desktop-with-fhs
      ];
    };
  }
