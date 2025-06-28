/**
  # Feature Module: AMD Graphics Support
  
  ## Description
  Comprehensive AMD GPU support for NixOS systems. Enables AMD GPU drivers,
  microcode updates, OpenCL compute support, and configures the display
  server for optimal AMD graphics performance.
  
  ## Platform Support
  - ✅ NixOS
  - ❌ Darwin (AMD GPUs not supported on macOS through this module)
  
  ## What This Enables
  - **AMD GPU Driver**: amdgpu kernel driver for modern AMD graphics cards
  - **Microcode Updates**: CPU microcode updates for AMD processors
  - **OpenCL Support**: GPU compute capabilities for applications
  - **32-bit Graphics**: Compatibility layer for 32-bit applications
  - **Display Manager**: GDM for graphical login
  - **X11 Server**: Configured with AMD GPU support
  
  ## Hardware Requirements
  - AMD GPU (GCN 1.0 or newer recommended)
  - AMD CPU (for microcode updates)
  
  ## Dependencies
  - Requires kernel modules: amdgpu
  - X11 or Wayland compositor support
  
  ## Performance Notes
  - Enables hardware acceleration for graphics and video
  - OpenCL support allows GPU compute workloads
  - Microcode updates improve CPU stability and performance
  
  ## Common Use Cases
  - Desktop systems with AMD graphics
  - Workstations requiring OpenCL compute
  - Gaming systems with AMD GPUs
*/
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
  }
