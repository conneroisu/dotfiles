{delib, ...}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.power-efficient";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      services = {
        ## Power-Efficient
        tlp.enable = true;
        power-profiles-daemon.enable = false;
      };
    };
  }
