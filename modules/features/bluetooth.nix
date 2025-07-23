/**
# Feature Module: Bluetooth Support

## Description
Complete Bluetooth stack configuration with GUI management tools.
Enables Bluetooth hardware, automatic device connection, and provides
both audio and data transfer capabilities with experimental features.

## Platform Support
- ✅ NixOS
- ❌ Darwin (macOS manages Bluetooth natively)

## What This Enables
- **Bluetooth Hardware**: Kernel-level Bluetooth support
- **Blueman**: GTK-based Bluetooth manager with system tray
- **Auto-connect**: Remembers and reconnects paired devices
- **Audio Profiles**: A2DP sink/source for audio devices
- **Experimental Features**: Latest Bluetooth capabilities

## Configuration Details
- **Power on Boot**: Bluetooth adapter starts automatically
- **Dual Mode**: Supports both classic and low energy (BLE)
- **Fast Connect**: Optimized connection speed
- **Auto Enable**: Services start automatically
- **Device Name**: Advertises as "Hello"

## Supported Profiles
- Source: Audio output to Bluetooth speakers/headphones
- Sink: Audio input from Bluetooth devices
- Media: Media control buttons (play/pause/skip)
- Socket: Low-level Bluetooth socket support

## Common Use Cases
- Wireless headphones and speakers
- Bluetooth keyboards and mice
- File transfer between devices
- Bluetooth game controllers
- Smart home device connectivity

## GUI Management
- Blueman provides system tray icon
- Device pairing and management
- Audio profile switching
- File transfer interface

## Troubleshooting
- Use `bluetoothctl` for command-line management
- Check `systemctl status bluetooth` for service status
- Experimental features may cause compatibility issues
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.bluetooth";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [
        pkgs.blueman
      ];
      services.blueman.enable = true;
      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings = {
            General = {
              Name = "Hello";
              ControllerMode = "dual";
              FastConnectable = "true";
              Experimental = "true";
              Enable = "Source,Sink,Media,Socket";
            };
            Policy = {
              AutoEnable = "true";
            };
          };
        };
      };
    };
  }
