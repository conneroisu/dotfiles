{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;

  program = pkgs.writeShellApplication {
    name = "hyprss";
    text = ./hyprss.sh;
    runtimeInputs = with pkgs; [
      grim
      wl-clipboard
      sqlite
      dunst
    ];
  };
in
  delib.module {
    name = "programs.hyprss";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [program];
    };
  }
