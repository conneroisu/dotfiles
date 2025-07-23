# rices.nix - Theme System Configuration Module
#
# This module manages the theming system (called "rices" in the context of system theming)
# using Stylix for consistent color schemes and styling across all applications.
#
# The rice system provides:
# - Centralized theme management through Stylix integration
# - Consistent Base16 color schemes across all applications
# - Automatic theming for supported programs and desktop environments
# - Per-host theme selection and customization
#
# Stylix Integration:
# - NixOS: Full system-wide theming including display managers and system services
# - Home Manager: User-space application theming (currently commented out but available)
# - Base16 color scheme support for consistent color palettes
#
# Usage:
# - Define rice configurations in the `rices/` directory
# - Set `myconfig.rice = "theme-name"` in host configurations
# - Stylix will automatically apply the theme to supported applications
{
  delib,
  inputs,
  ...
}:
delib.module {
  name = "rices";

  options = with delib; let
    # Rice (theme) submodule definition
    # Inherits standard rice options from delib framework
    rice = {
      options = riceSubmoduleOptions;
    };
  in {
    # Single rice configuration option
    rice = riceOption rice;
    # Multiple rices configuration option
    rices = ricesOption rice;
  };

  # Home Manager configuration
  # Note: Stylix home-manager module is currently disabled but available
  home.always = {myconfig, ...}: {
    # imports = [inputs.stylix.homeModules.stylix];

    # Validate that all referenced rice names exist in the rices directory
    assertions = delib.riceNamesAssertions myconfig.rices;
  };

  # NixOS configuration with full Stylix integration
  nixos.always = {myconfig, ...}: {
    # Import Stylix module for system-wide theming
    imports = [inputs.stylix.nixosModules.stylix];

    # Validate that all referenced rice names exist in the rices directory
    assertions = delib.riceNamesAssertions myconfig.rices;
  };
}
