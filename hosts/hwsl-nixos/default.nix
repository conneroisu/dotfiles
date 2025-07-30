/**
# Host Configuration: hwsl-nixos

## Description
WSL (Windows Subsystem for Linux) configuration running NixOS.
This host is configured for development in a WSL environment.

## Host Type
- Type: server (headless WSL)
- System: x86_64-linux
- Rice: dark theme

## Key Features
- **WSL integration**: Native Windows Subsystem for Linux support
- **Development environment**: Full engineering toolchain
- **Container support**: K3s agent for Kubernetes development
- **Secrets management**: Secure credential handling

## WSL Configuration
- NixOS-WSL module for WSL integration
- Minimal hardware configuration (virtual environment)
- No boot loader configuration (managed by WSL)

## System Configuration
- Locale: en_US.UTF-8 (Chicago timezone)
- RTKit for real-time audio processing
- Container runtime support

## Security
- Determinate Systems hardening
- Secrets management enabled
- WSL-specific security considerations
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

    # WSL doesn't use traditional boot loaders
    # Boot configuration is managed by the WSL environment

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
