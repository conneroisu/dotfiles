/**
# Host Configuration: xps-nixos (Dell XPS Laptop)

## Description
Mobile workstation configuration for a Dell XPS laptop running NixOS.
Optimized for battery life and NVIDIA Optimus graphics switching between
Intel integrated and NVIDIA discrete GPUs. Full development and study
environment.

## Host Type
- Type: laptop
- System: x86_64-linux
- Rice: dark theme

## Key Features
- **Hybrid graphics**: NVIDIA Optimus (Intel + NVIDIA GPU switching)
- **Power optimization**: Battery life enhancements enabled
- **Full desktop**: Hyprland Wayland compositor
- **Development & Study**: Both engineer and student roles
- **Gaming support**: Proton-X for Windows game compatibility
- **Privacy & Security**: Darknet features and secrets management

## Hardware Support
- NVIDIA proprietary drivers with PRIME offloading
- Intel integrated graphics (Bus ID: PCI:0:2:0)
- NVIDIA discrete GPU (Bus ID: PCI:1:0:0)
- Audio subsystem with PipeWire
- Bluetooth connectivity
- Printer support via CUPS

## System Configuration
- Systemd-boot with Plymouth boot splash
- Locale: en_US.UTF-8 (Chicago timezone)
- RTKit for real-time audio
- libinput for touchpad and input devices
- Limited boot history (4 generations)

## Unique Programs
- proton-x: Custom Proton/Wine wrapper for gaming

## Use Cases
- Software development (engineer role)
- Academic work (student role)
- Gaming with Proton compatibility
- Privacy-focused computing
*/
{
  delib,
  inputs,
  pkgs,
  ...
}:
delib.host {
  name = "xps-nixos";

  rice = "dark";
  type = "laptop";
  home.home.stateVersion = "24.11";

  darwin = {
    imports = [
      inputs.determinate.darwinModules.default
    ];
    nixpkgs.hostPlatform = "aarch64-darwin";
    system.stateVersion = "24.11";
  };

  nixos = {
    imports = [
      inputs.determinate.nixosModules.default
    ];

    myconfig = {
      features = {
        nvidia.enable = true;
        power-efficient.enable = true;
        audio.enable = true;
        bluetooth.enable = true;
        hyprland.enable = true;
        engineer.enable = true;
        darknet.enable = true;
        secrets.enable = true;
        student.enable = true;
      };
      programs = {
        proton-x.enable = true;
      };
    };

    nixpkgs.config.allowUnfree = true;
    nixpkgs.hostPlatform = "x86_64-linux";
    boot = {
      plymouth.enable = true;
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        systemd-boot.configurationLimit = 4;
      };
    };

    networking = {
      hostName = "xps-nixos";
      networkmanager.enable = true;
      defaultGateway = {
        #   # address = "192.168.1.1";
        #   # interface = "wlp0s20f3";
        address = "192.168.1.19";
        #   # interface = "enp0s13f0u3u1c2";
        interface = "enp0s13f0u3c2";
      };
    };

    hardware = {
      enableAllFirmware = true;
      nvidia = {
        prime = {
          # Bus ID of the Intel GPU.
          intelBusId = "PCI:0:2:0";
          # Bus ID of the NVIDIA GPU.
          nvidiaBusId = "PCI:1:0:0";
        };
      };
    };
    security.rtkit.enable = true;
    services = {
      ## Devices
      printing.enable = true;
      libinput.enable = true;
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
