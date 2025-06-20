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

    nixos.ifEnabled = rec {
      hardware.cpu.intel.updateMicrocode = pkgs.lib.mkDefault hardware.enableRedistributableFirmware;
    };
  }
