{delib, ...}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.nvidia";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      # Load nvidia driver for Xorg and Wayland
      hardware = {
        nvidia = {
          open = false;
          prime = {
            reverseSync.enable = true;
            offload = {
              enable = true;
              enableOffloadCmd = true;
            };
          };
          powerManagement = {
            # Enable NVIDIA power management.
            enable = true;

            # Enable dynamic power management.
            finegrained = true;
          };
        };
        graphics = {
          enable = true;
          enable32Bit = true;
        };
      };

      services = {
        displayManager = {
          gdm.enable = true;
        };
        ## Graphics
        xserver = {
          enable = true;
          videoDrivers = ["nvidia"];
          xkb = {
            layout = "us";
            variant = "";
          };
        };
      };
    };
  }
