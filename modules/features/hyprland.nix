{
  delib,
  pkgs,
  inputs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.hyprland";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      environment = {
        systemPackages =
          (with inputs; [
            ghostty.packages."${pkgs.system}".default
            ashell.packages.${pkgs.system}.default
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
            (pkgs.rofi.override {
              plugins = [
                pkgs.rofi-rbw
                pkgs.rofi-calc
              ];
            })
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
          package = inputs.hyprland.packages.${pkgs.system}.default;
          portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
          enable = true;
          withUWSM = true;
          xwayland.enable = true;
        };
      };

      services = {
        dbus.enable = true;
        gvfs.enable = true; # Mount, trash, and other functionalities
        tumbler.enable = true; # Thumbnails
        hypridle.enable = true;
      };

      xdg = {
        portal = {
          enable = true;
          extraPortals = [inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland];

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
            "image/octet-stream" = "zen.desktop";
            # PDF
            "application/pdf" = "org.gnome.Evince.desktop";
            # PNG, JPG
            "image/png" = "org.gnome.eog.desktop";
            "image/jpeg" = "org.gnome.eog.desktop";
            "image/jpg" = "org.gnome.eog.desktop";
            "image/gif" = "org.gnome.eog.desktop";
            "image/webp" = "org.gnome.eog.desktop";
            "image/bmp" = "org.gnome.eog.desktop";
            "image/tiff" = "org.gnome.eog.desktop";
            "image/svg+xml" = "org.gnome.eog.desktop";
            "image/ppm" = "org.gnome.eog.desktop";
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
