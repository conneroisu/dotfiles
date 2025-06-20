{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.intel";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      hardware.cpu.intel.updateMicrocode = true;
    };
  }
