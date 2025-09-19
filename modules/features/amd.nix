{delib, ...}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.amd";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      # Load amd driver for Xorg and Wayland
      hardware = {
        cpu.amd.updateMicrocode = true;
        amdgpu.opencl.enable = true;
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
          videoDrivers = ["amdgpu"];
          xkb = {
            layout = "us";
            variant = "";
          };
        };
      };
    };

    darwin.ifEnabled = {
      # AMD GPU support not applicable on Darwin/macOS
    };

    home.ifEnabled = {
      # AMD-specific home configuration can be added here if needed
    };
  }
