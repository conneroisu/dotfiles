/**
# Feature Module: GNOME Desktop Environment

## Description
Minimal GNOME desktop environment setup with essential services and display management.
Provides a traditional desktop experience with modern polish and accessibility features.
Focused on core GNOME services without heavy application defaults.

## Platform Support
- ✅ NixOS
- ❌ Darwin (GNOME is Linux-only)

## What This Enables
- **Display Manager**: GDM (GNOME Display Manager)
- **Security Services**: GNOME Keyring integration with PAM
- **Core Services**: D-Bus, GVFS (virtual filesystems), Tumbler (thumbnails)
- **X11 Server**: Basic X server configuration for GNOME session

## Usage Notes
- Minimal GNOME setup - additional applications should be configured separately
- GDM provides the login interface and session management
- GNOME Keyring handles password and secret storage
- GVFS enables mount/unmount operations and trash functionality
*/
{
  delib,
  pkgs,
  inputs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.gnome";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment = {
        systemPackages = [
        ];
        variables = {
        };
      };

      security.pam.services.sddm.enableGnomeKeyring = true;
      services = {
        gnome.gnome-keyring.enable = true;
        gvfs.enable = true; # Mount, trash, and other functionalities
        tumbler.enable = true; # Thumbnails
        dbus = {
          enable = true;
          implementation = "broker";
        };
        xserver = {
          enable = true;
        };
        displayManager.gdm.enable = true;
      };
    };
  }
