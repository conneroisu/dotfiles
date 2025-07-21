# TODO: Add header
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

      programs = {
        gnome.enable = true;
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
          displayManager.gdm.enable = true;
        };
      };
    };
  }
