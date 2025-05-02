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

  roofi = pkgs.rofi.override {
    plugins = [
      pkgs.rofi-rbw
      pkgs.rofi-obsidian
      pkgs.rofi-bluetooth
      pkgs.rofi-power-menu
      pkgs.rofi-calc
    ];
  };
in {
  options.${namespace}.wm.hyprland = with types; {
    enable = mkEnableOption "Enable Hyprland";
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      (with inputs; [
        ghostty.packages."${system}".default
        ashell.packages.${system}.default
      ])
      ++ (with pkgs; [
        hyprcursor
        hyprkeys
        hyprpaper
        playerctl
        hypridle
        hyprsunset
        hyprwayland-scanner
        hyprutils
        wl-clipboard
        hyprnotify
        uwsm
        grimblast
        grim
        slurp
        roofi
        dunst
        brightnessctl
        hyprls
        gnome-control-center
        spotify-cli-linux
        hyprpicker
        gpu-screen-recorder
        ffmpegthumbnailer
      ]);

    programs = {
      dconf.enable = true;
      hyprland = {
        package = inputs.hyprland.packages."${system}".hyprland;
        portalPackage = inputs.hyprland.packages."${system}".xdg-desktop-portal-hyprland;
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
      gvfs.enable = true; # Mount, trash, and other functionalities
      tumbler.enable = true; # Thumbnails
      hypridle.enable = true;
    };

    xdg = {
      portal = {
        enable = true;
        extraPortals = [inputs.hyprland.packages."${system}".xdg-desktop-portal-hyprland];

        config.hyprland = {
          default = [
            "gtk"
            "wlr"
          ];
          "org.freedesktop.impl.portal.FileChooser" = "gtk";
        };
      };
      mime = {
        enable = true;

        defaultApplications = {
          # PDF
          "application/pdf" = "org.gnome.Evince.desktop";
          # PNG, JPG
          "image/png" = "org.gnome.Loupe.desktop";
          "image/jpeg" = "org.gnome.Loupe.desktop";
          "image/ppm" = "org.gnome.Loupe.desktop";
          # Directories
          "inode/directory" = "thunar.desktop";
          "x-scheme-handler/file" = "thunar.desktop";
          # .txt
          "text/plain" = "nvim.desktop";
        };
      };
    };
  };
}
