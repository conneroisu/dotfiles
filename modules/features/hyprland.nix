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

    nixos.ifEnabled = {
      environment = {
        systemPackages =
          [
            inputs.ghostty.packages."${pkgs.system}".default
            inputs.ashell.defaultPackage.${pkgs.system}
          ]
          ++ [
            pkgs.hyprcursor
            pkgs.hyprkeys
            pkgs.hyprpaper
            pkgs.playerctl
            pkgs.hypridle
            pkgs.hyprsunset
            pkgs.hyprwayland-scanner
            pkgs.hyprutils
            pkgs.wl-clipboard
            pkgs.hyprnotify
            pkgs.uwsm
            pkgs.grimblast
            pkgs.grim
            pkgs.slurp
            pkgs.kitty
            (pkgs.rofi.override {
              plugins = [
                pkgs.rofi-rbw
                pkgs.rofi-calc
              ];
            })
            pkgs.dunst
            pkgs.brightnessctl
            pkgs.hyprls
            pkgs.gnome-control-center
            pkgs.hyprpicker
            pkgs.gpu-screen-recorder
            pkgs.ffmpegthumbnailer
          ];
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

      security.pam.services.sddm.enableGnomeKeyring = true;
      services = {
        gnome.gnome-keyring.enable = true;
        dbus.enable = true;
        gvfs.enable = true; # Mount, trash, and other functionalities
        tumbler.enable = true; # Thumbnails
        hypridle.enable = true;
      };

      myconfig.programs.wayss.enable = true;
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
            # PDF
            "application/pdf" = "org.gnome.Evince.desktop";
            # PNG, JPG
            "image/png" = "org.gnome.Loupe.desktop";
            "image/jpeg" = "org.gnome.Loupe.desktop";
            "image/ppm" = "org.gnome.Loupe.desktop";
            # Directories
            "inode/directory" = "nemo.desktop";
            "x-scheme-handler/file" = "nemo.desktop";
            # .txt
            "text/plain" = "nvim.desktop";
          };
        };
      };
    };
  }
