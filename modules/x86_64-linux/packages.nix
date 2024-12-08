{ pkgs, unstable-pkgs, ... }:

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
  pkgs.xdg-desktop-portal-hyprland
  pkgs.uwsm
  pkgs.tlp
  pkgs.dunst
  pkgs.pipewire
  pkgs.grimblast
  pkgs.grim
  pkgs.slurp
  pkgs.rofi
  pkgs.brightnessctl
  pkgs.xfce.thunar

  pkgs.alsa-utils
  pkgs.alsa-lib
  pkgs.alsa-oss

  pkgs.dockutil

]
