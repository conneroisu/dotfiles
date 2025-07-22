/**
# Host Configuration: oxe-nixos

## Description
Server/workstation configuration running NixOS with full desktop capabilities.
This host is configured as a server type but includes a complete Hyprland
desktop environment for when GUI access is needed.

## Host Type
- Type: server
- System: x86_64-linux (assumed, imports AMD module)
- Rice: dark theme

## Key Features
- **Full desktop server**: Hyprland Wayland compositor
- **AMD graphics**: Optimized for AMD GPUs
- **Audio/Bluetooth**: Full multimedia support
- **Development environment**: Engineer role enabled
- **Privacy tools**: Darknet features enabled
- **Secrets management**: Secure credential handling

## Hardware Support
- AMD GPU drivers and optimizations
- Audio subsystem with PipeWire (assumed via audio feature)
- Bluetooth connectivity
- Hardware configuration imported from ./hardware.nix

## System Configuration
- Systemd-boot with Plymouth boot splash
- Locale: en_US.UTF-8 (Chicago timezone)
- RTKit for real-time audio
- libinput for input device handling

## Security
- Determinate Systems hardening
- Secrets management enabled
- Limited boot history (4 generations)
*/
{
  delib,
  inputs,
  ...
}:
delib.host {
  name = "oxe-nixos";

  rice = "dark";
  type = "server";
  home.home.stateVersion = "24.11";

  darwin = {
    imports = [
      inputs.determinate.darwinModules.default
    ];
    nixpkgs.hostPlatform = "aarch64-darwin";
    system.stateVersion = "24.11";
  };

  nixos = {
    nixpkgs.config.allowUnfree = true;
    imports = [
      inputs.determinate.nixosModules.default
      ./hardware.nix
    ];

    myconfig = {
      features = {
        amd.enable = true;
        hyprland.enable = true;
        engineer.enable = true;
        darknet.enable = true;
        secrets.enable = true;
      };
    };

    boot = {
      plymouth.enable = true;
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        systemd-boot.configurationLimit = 4;
      };
    };

    security = {
      rtkit.enable = true;
      pam.services.login.enableGnomeKeyring = true;
    };

    time.timeZone = "America/Chicago";
    i18n = {
      # Select internationalisation properties.
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
    };
  };
}
