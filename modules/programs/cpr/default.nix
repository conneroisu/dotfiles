{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
  program = pkgs.writeShellApplication "cpr" {
    text = ''
      gh pr list | cut -f1,2 | gum choose | cut -f1 | xargs gh pr checkout
    '';

    runtimeInputs = [
      pkgs.coreutils
      pkgs.gum
      pkgs.gh
    ];
  };
in
  delib.module {
    name = "programs.cpr";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [
        program
      ];
    };

    darwin.ifEnabled = {
      environment.systemPackages = [
        program
      ];
    };
  }
