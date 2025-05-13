{
  lib,
  pkgs,
  inputs,
  namespace,
  system,
  config,
  ...
}:
with lib; let
  cfg = config.${namespace}.wm.hyprland;

  roofi = pkgs.rofi.override {
    plugins = [
      pkgs.rofi-rbw
      pkgs.rofi-calc
    ];
  };
in {
  options.${namespace}.wm.hyprland = with types; {
    enable = mkEnableOption "Enable Hyprland";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages =
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
          hyprpicker
          gpu-screen-recorder
          ffmpegthumbnailer
        ]);
      variables = {
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "Hyprland";
        XDG_CURRENT_DESKTOP = "Hyprland";
        GDK_BACKEND = "wayland,x11,*";
        GTK_THEME = "Adwaita:dark";
        GBM_BACKEND = "nvidia-drm";
        SDL_VIDEODRIVER = "wayland";
        CLUTTER_BACKEND = "wayland";
        QT_QPA_PLATFORM = "wayland;xcb";
      };
    };

    programs = {
      dconf.enable = true;
      hyprland = {
        package = pkgs.hyprland;
        portalPackage = pkgs.xdg-desktop-portal-hyprland;
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
        extraPortals = [pkgs.xdg-desktop-portal-hyprland];

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
