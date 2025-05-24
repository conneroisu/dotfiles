{
  pkgs,
  lib,
  delib,
  ...
}: let
  inherit (delib) singleEnableOption;
  program = pkgs.buildGoModule {
    name = "cmbd";
    src = ./.;
    vendorHash = null;
  };
in
  delib.module {
    name = "programs.cmbd";
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
