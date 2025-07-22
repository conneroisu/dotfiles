# hosts.nix - Host Type Definitions and Feature Mapping Module
#
# This module defines the host classification system used throughout the configuration.
# It provides a structured way to categorize systems and automatically enable appropriate
# features based on the host type.
#
# Host Types:
# - desktop: Full-featured workstation (cli, gui, engineer features)
# - laptop: Portable system with power management (cli, gui, engineer, powersave, nvidia)
# - server: Headless system with minimal features (cli only)
#
# Features System:
# - cli: Command-line utilities (eza, bat, nh, etc.) - essential tools for productivity
# - gui: GUI applications and desktop environment modules (gnome-keyring, wakatime, etc.)
# - engineer: Development tools and programming environments
# - powersave: Power management and battery optimization (laptop-specific)
#
# Display Configuration:
# - Multi-monitor support with per-display settings
# - Automatic kernel parameter generation for display resolution
# - Touch screen detection and configuration
{delib, ...}:
delib.module {
  name = "hosts";

  options = with delib; let
    # Available feature categories that can be enabled per host type
    allFeatures = ["cli" "gui" "engineer" "powersave"];

    # Host submodule definition with type-specific feature defaults
    host = {config, ...}: {
      options =
        hostSubmoduleOptions
        // {
          # Required: Host type classification
          type = noDefault (enumOption ["desktop" "server" "laptop"] null);

          # Computed boolean flags for convenient host type checking
          isDesktop = boolOption (config.type == "desktop");
          isLaptop = boolOption (config.type == "laptop");
          isServer = boolOption (config.type == "server");

          # Feature enablement with sensible defaults per host type
          # Features are automatically selected based on host type but can be overridden
          features =
            listOfOption (enum allFeatures)
            {
              # Desktop: Full-featured workstation setup
              desktop = ["features.engineer"];
              # Server: Minimal headless configuration
              server = [""];
              # Laptop: Full features + power management + NVIDIA support
              laptop = ["cli" "gui" "features.engineer" "features.power-efficient" "features.nvidia"];
            }
            .${
              config.type
            };

          # Display configuration for multi-monitor setups
          displays = listOfOption (submodule {
            options = {
              # Display state
              enable = boolOption true;
              touchscreen = boolOption false;

              # Display identification (e.g. DP-1, HDMI-A-1, eDP-1)
              name = noDefault (strOption null);

              # Primary display detection (auto-set for single display)
              primary = boolOption (builtins.length config.displays == 1);

              # Display properties
              refreshRate = intOption 60; # Default to 60Hz
              width = intOption 1920; # Default to 1920x1080
              height = intOption 1080;
              x = intOption 0; # Position in multi-monitor setup
              y = intOption 0;
            };
          }) [];
        }
        //
        # Generate boolean options for each feature (e.g., cliFeatured, guiFeatured)
        # This allows modules to check `myconfig.host.cliFeatured` easily
        builtins.listToAttrs (
          map (feature: {
            name = "${feature}Featured";
            value = boolOption (builtins.elem feature config.features);
          })
          allFeatures
        );
    };
  in {
    # Single host configuration option
    host = hostOption host;
    # Multiple hosts configuration option
    hosts = hostsOption host;
  };

  # Make host configurations available as shared arguments
  myconfig.always = {myconfig, ...}: {
    args.shared = {
      inherit (myconfig) host hosts;
    };
  };

  # NixOS-specific configuration
  # Automatically configure kernel video parameters based on display settings
  nixos.always = {myconfig, ...}: {
    boot.kernelParams = map (display: with display; "video=${name}:${toString width}x${toString height}@${toString refreshRate}") myconfig.host.displays;
  };

  # Home Manager configuration with host name validation
  home.always = {myconfig, ...}: {
    assertions = delib.hostNamesAssertions myconfig.hosts;
  };
}
