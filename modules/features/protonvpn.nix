/**
TODO: Add documentation
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.protonvpn";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      networking.firewall.checkReversePath = false;
      environment.systemPackages = with pkgs; [wireguard-tools protonvpn-gui];
    };
  }
