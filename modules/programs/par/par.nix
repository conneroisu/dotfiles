{
  pkgs,
  lib,
  delib,
  ...
}: let
  inherit (delib) singleEnableOption;
  program = pkgs.buildGoModule {
    name = "par";
    src = ./.;
    vendorHash = null;
  };
in
  delib.module {
    name = "programs.par";
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
