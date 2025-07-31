/**
# Host Configuration: hwsl-nixos

## Description
WSL2 NixOS environment for development and containerization.
This host is configured as a server type running inside WSL2.

## Host Type
- Type: server
- System: x86_64-linux
- Rice: dark theme

## Key Features
- **WSL2 integration**: Windows Subsystem for Linux v2
- **Development environment**: Engineer role enabled
- **Container support**: k3s agent for Kubernetes clusters
- **Privacy tools**: Darknet features enabled
- **Secrets management**: Secure credential handling

## Hardware Support
- WSL2 virtual hardware
- No traditional boot loader (managed by WSL)

## System Configuration
- Locale: en_US.UTF-8 (Chicago timezone)
- RTKit for real-time audio
- No Plymouth boot splash

## Security
- Determinate Systems hardening
- Secrets management enabled
- k3s agent for cluster participation
*/
{
  delib,
  inputs,
  ...
}:
delib.host {
  name = "hwsl-nixos";

  rice = "dark";
  type = "server";
  home.home.stateVersion = "24.11";

  darwin = {
    imports = [
      inputs.determinate.darwinModules.default
    ];
    nixpkgs.hostPlatform = "x86_64-darwin";
    system.stateVersion = "24.11";
  };

  nixos = {
    nixpkgs.config.allowUnfree = true;
    imports = [
      inputs.determinate.nixosModules.default
      inputs.nixos-wsl.nixosModules.default
      ./hardware.nix
    ];

    myconfig = {
      features = {
        engineer.enable = true;
        darknet.enable = true;
        secrets.enable = true;

        k3sAgent.enable = true;
      };
    };

    wsl.enable = true;

    boot = {
      plymouth.enable = false;
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
