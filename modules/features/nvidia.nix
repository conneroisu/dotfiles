/**
# Feature Module: NVIDIA Graphics Support

## Description
Comprehensive NVIDIA GPU support with proprietary drivers, power management,
and Optimus laptop configurations. Optimized for both desktop and laptop
systems with NVIDIA graphics, including hybrid Intel+NVIDIA setups.

## Platform Support
- ✅ NixOS
- ❌ Darwin (NVIDIA drivers not available on macOS)

## What This Enables
- **Proprietary NVIDIA Drivers**: Closed-source drivers for best performance
- **PRIME Offloading**: Dynamic GPU switching for laptops
- **Power Management**: Fine-grained control to save battery
- **CUDA Support**: GPU compute capabilities
- **Hardware Video Acceleration**: NVENC/NVDEC
- **Vulkan/OpenGL**: Full 3D acceleration

## Key Features
### PRIME Technology
- **Reverse Sync**: Better performance for external displays
- **Offload Mode**: Run specific apps on NVIDIA GPU
- **Dynamic Switching**: Automatic GPU selection
- **Power Saving**: NVIDIA GPU powers down when idle

### Power Management
- **Fine-grained Control**: Per-component power management
- **Dynamic Power**: Adjusts based on workload
- **Suspend/Resume**: Proper sleep state handling
- **Battery Optimization**: Extends laptop battery life

### Graphics Stack
- Full OpenGL support with GLX
- Vulkan with ray tracing (RTX cards)
- CUDA toolkit compatibility
- OpenCL compute support
- Hardware video encoding/decoding

## Hardware Configurations
### Desktop Systems
- Single NVIDIA GPU setup
- Multi-GPU SLI configurations
- Professional Quadro cards

### Laptop Systems (Optimus)
- Intel integrated + NVIDIA discrete
- AMD integrated + NVIDIA discrete
- External display support via NVIDIA
- Dynamic power management

## Common Use Cases
- CUDA development and compute
- Machine learning workloads
- Video editing with NVENC
- 3D rendering and CAD
- Multiple high-resolution displays

## Configuration Notes
- Uses proprietary drivers (open = false)
- PRIME configured per-host (see hosts/)
- Wayland support via XWayland
- May require kernel parameters

## Troubleshooting
- Check `nvidia-smi` for GPU status
- Use `nvidia-offload <app>` for PRIME
- Monitor temps with `nvidia-settings`
- Power state: `/sys/bus/pci/devices/`

## Performance Tips
- Enable Force Composition Pipeline for tearing
- Use `__NV_PRIME_RENDER_OFFLOAD=1` for offloading
- Configure TDP limits for efficiency
- Enable GPU boost for performance
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.nvidia";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      # Load nvidia driver for Xorg and Wayland
      virtualisation.docker.enableNvidia = true;
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
      # hardware.nvidia-container-toolkit.enable = true;

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

      environment = {
        systemPackages = with pkgs; [
          nvtopPackages.intel
        ];
        variables = {
          LIBVA_DRIVER_NAME = "nvidia";
        };
      };
    };
  }
