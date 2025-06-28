# args.nix - Shared Arguments Configuration Module
#
# This module manages the argument passing system between different configuration contexts
# (NixOS, Home Manager, and shared). It provides a centralized way to pass values and
# configurations between modules across different platforms.
#
# The args system allows:
# - Shared arguments available to both NixOS and Home Manager configurations
# - Platform-specific arguments for NixOS-only or Home Manager-only contexts
# - Consistent argument propagation through the module system
#
# Usage:
# - Set `myconfig.args.shared.someValue = "value"` to make it available everywhere
# - Set `myconfig.args.nixos.someValue = "value"` for NixOS-specific arguments
# - Set `myconfig.args.home.someValue = "value"` for Home Manager-specific arguments

{delib, ...}:
delib.module {
  name = "args";

  options.args = with delib; {
    # Shared arguments available to both NixOS and Home Manager configurations
    shared = attrsLegacyOption {};
    
    # NixOS-specific arguments only available in NixOS context
    nixos = attrsLegacyOption {};
    
    # Home Manager-specific arguments only available in Home Manager context
    home = attrsLegacyOption {};
  };

  # NixOS configuration: merge shared and NixOS-specific arguments
  nixos.always = {cfg, ...}: {
    imports = [
      {_module.args = cfg.shared // cfg.nixos;}
    ];
  };

  # Home Manager configuration: merge shared and Home Manager-specific arguments
  home.always = {cfg, ...}: {
    imports = [
      {_module.args = cfg.shared // cfg.home;}
    ];
  };
}
