{
  lib,
  pkgs,
  config,
  inputs,
  username,
  ...
}: let
  inherit
    (lib)
    ns
    mkEnableOption
    mkOption
    optionals
    types
    mkAliasOptionModule
    attrNames
    mkDefault
    ;
  cfg = config.${ns}.services;
in {
  wgnord = {
    enable = mkEnableOption "Wireguard NordVPN";
    confinement.enable = mkEnableOption "Confinement Wireguard NordVPN";

    excludeSubnets = mkOption {
      type = with types; listOf str;
      default = [];
      description = ''
        List of subnets to exclude from being routed through the VPN. Does
        not apply to the confinement VPN.
      '';
    };
  };
}
