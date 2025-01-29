{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  config,
  ...
}:
with lib; let
  cfg = config.${namespace}.wm.hyprland;
in {
  options.${namespace}.wm.hyprland = with types; {
    enable = mkEnableOption "Enable Hyprland";
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      (with inputs; [
        ghostty.packages."${system}".default
        ashell.defaultPackage.${system}
      ])
      ++ (with pkgs; [
        (pkgs.hyprland.override {
          debug = true;
        })
        hyprcursor
        hyprkeys
        hyprpaper
        hypridle
        hyprsunset
        hyprwayland-scanner
        hyprutils
        wl-clipboard
        hyprnotify
        waybar
        uwsm
        xdg-desktop-portal-hyprland
        grimblast
        grim
        slurp
        rofi
        rofi-rbw
        rofi-obsidian
        rofi-bluetooth
        rofi-power-menu
        dunst
        brightnessctl
        hyprls
        gnome-control-center
      ]);

    programs = {
      dconf.enable = true;
      hyprland = {
        enable = true;
        withUWSM = true;
        xwayland.enable = true;
      };
      hyprlock.enable = true;
    };

    # Enable OpenGL
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    services = {
      hypridle.enable = true;
    };
  };
}
