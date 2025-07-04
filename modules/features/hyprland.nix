/**
# Feature Module: Hyprland Desktop Environment

## Description
Complete Hyprland Wayland compositor setup with a modern, tiling window
manager environment. Provides a full desktop experience with animations,
effects, and extensive customization options for power users who prefer
keyboard-driven workflows.

## Platform Support
- ✅ NixOS
- ❌ Darwin (Wayland compositors are Linux-only)

## What This Enables
- **Hyprland**: Dynamic tiling Wayland compositor
- **Terminal Emulators**: Ghostty, Kitty, Alacritty, Foot
- **Application Launchers**: Rofi with plugins, Walker
- **Status Bars**: Waybar with custom styling
- **Notifications**: Dunst notification daemon
- **Media Controls**: Audio/video control integration
- **Screenshot Tools**: Grim, Slurp, Grimblast

## Core Components
### Window Management
- Dynamic tiling with smooth animations
- Multiple workspace support
- Window rules and special workspaces
- Picture-in-picture mode
- Fullscreen and floating windows

### Desktop Utilities
- **hyprcursor**: Cursor theme support
- **hyprpaper**: Wallpaper manager
- **hypridle**: Idle management daemon
- **hyprsunset**: Blue light filter
- **hyprnotify**: Native notifications

### Terminal Emulators
- Ghostty: Modern GPU-accelerated terminal
- Kitty: Feature-rich terminal with images
- Alacritty: Minimal GPU-accelerated terminal
- Foot: Lightweight Wayland terminal

### Application Launcher (Rofi)
- Application launcher
- Window switcher
- Power menu
- Calculator plugin
- Clipboard manager
- Password manager integration

### Media & Screen Tools
- wl-clipboard: Wayland clipboard utilities
- grim/slurp: Screenshot and region selection
- grimblast: Screenshot wrapper with effects
- playerctl: Media player control
- pavucontrol: Audio control GUI

## Display Protocols
- Native Wayland support
- XWayland for legacy X11 applications
- UWSM: Universal Wayland Session Manager
- GPU acceleration with EGL/GLES

## Common Use Cases
- Tiling window management workflows
- Multi-monitor setups
- Gaming with low latency
- Development environments
- Media production

## Integration Points
- Works with audio/bluetooth features
- Integrates with engineer tools
- Theme support via rice system
- Hardware acceleration (AMD/NVIDIA)

## Key Bindings
Configured through Hyprland config with:
- Super key as primary modifier
- Vim-like navigation
- Application shortcuts
- Workspace management
- Window manipulation
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
        gvfs.enable = true; # Mount, trash, and other functionalities
        tumbler.enable = true; # Thumbnails
        hypridle.enable = true;
        dbus = {
          enable = true;
          implementation = "broker";
        };
      };

      xdg = {
        portal = {
          enable = true;
          wlr.enable = true;
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
