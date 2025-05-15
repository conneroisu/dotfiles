{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.darknet";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      services = {
        tailscale.enable = true;
        fail2ban.enable = true;
      };
    };
  }
