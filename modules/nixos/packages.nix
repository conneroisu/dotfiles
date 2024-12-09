{ inputs, pkgs, unstable-pkgs, ... }:

let
  shared-packages = import ../shared/packages.nix { inherit pkgs unstable-pkgs; };
in
shared-packages
++ [
  pkgs.nh
  pkgs.nix-ld
  pkgs.hyprland
  pkgs.hyprcursor
  pkgs.hyprkeys
  pkgs.hyprpaper
  pkgs.hyprsunset
  pkgs.hyprwayland-scanner
  pkgs.hyprutils
  pkgs.hyprlock
  pkgs.hypridle
  pkgs.hyprnotify
  pkgs.xdg-desktop-portal-hyprland
  pkgs.uwsm
  pkgs.tlp
  pkgs.dunst
  pkgs.pipewire
  pkgs.grimblast
  pkgs.grim
  pkgs.slurp
  pkgs.rofi
  pkgs.rofi-calc
  pkgs.rofi-obsidian
  pkgs.rofi-bluetooth
  unstable-pkgs.rofi-pass-wayland
  pkgs.brightnessctl
  pkgs.xfce.thunar
  pkgs.wineWowPackages.stable
  pkgs.fontconfig
  pkgs.font-manager
  pkgs.chromedriver
  pkgs.libusb1
  pkgs.evince
  inputs.zen-browser.packages."${system}".default

  pkgs.alsa-utils
  pkgs.alsa-lib
  pkgs.alsa-oss

  pkgs.dockutil

]
