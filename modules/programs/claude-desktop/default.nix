{
  delib,
  inputs,
  system,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "programs.cmbd";
    options = singleEnableOption false;
    nixos.ifEnabled = {
      environment.systemPackages = [
        inputs.claude-desktop.packages.${system}.claude-desktop
      ];
    };
  }
