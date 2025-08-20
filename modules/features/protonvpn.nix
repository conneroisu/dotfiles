/**
ProtonVPN Feature Module

This module enables ProtonVPN support on NixOS systems by:
- Installing ProtonVPN GUI client and WireGuard tools
- Disabling reverse path checking in the firewall (required for VPN functionality)

The module provides a system-level VPN solution using ProtonVPN's official client
with WireGuard protocol support for secure and private internet access.

Usage:
  myconfig.features.protonvpn = true;

Dependencies:
- wireguard-tools: Core WireGuard utilities for VPN protocol
- protonvpn-gui: Official ProtonVPN graphical client

Note: Only available on NixOS systems (not macOS/Darwin)
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
