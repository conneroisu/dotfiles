{delib, ...}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.power-efficient";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      services = {
        tlp.enable = true;
        power-profiles-daemon.enable = false;
      };
    };
  }
