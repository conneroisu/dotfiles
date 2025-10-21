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
- **hyprsunset**: Blue light filter
- **hyprnotify**: Native notifications

### Terminal Emulators
- Ghostty: Modern GPU-accelerated terminal
- Kitty: Feature-rich terminal with images

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
  lib,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.hyprland";

    options = singleEnableOption false;
    nixos.ifEnabled = {
      myconfig.programs = {
        ghostty.enable = true;
        explorer.enable = true;
        hyprss.enable = true;
      };
      environment = {
        systemPackages =
          [
            inputs.ghostty.packages."${pkgs.system}".default
            inputs.hyprland.packages."${pkgs.system}".default
            (inputs.hyprshell.helpers.wrap-hyprshell
            inputs.hyprland.packages."${pkgs.system}".default
            pkgs)
            (pkgs.rofi.override {
              plugins = [
                pkgs.rofi-rbw
                pkgs.rofi-calc
              ];
            })
          ]
          ++ (with pkgs; [
            evince
            kdePackages.konsole
            wl-clip-persist
            hyprcursor
            hyprkeys
            hyprpaper
            playerctl
            hyprsunset # Needs cc at runtime
            stdenv.cc
            xmlstarlet
            hyprwayland-scanner
            hyprutils
            wl-clipboard
            hyprnotify
            uwsm
            grimblast
            grim
            slurp
            kitty
            dunst
            brightnessctl
            hyprls
            swaynotificationcenter
            gnome-control-center
            hyprpicker
            gpu-screen-recorder
            ffmpegthumbnailer
            pipewire
          ]);
      };

      hardware = {
        graphics = {
          extraPackages = with pkgs; [
            mesa
          ];
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

      security = {
        pam.services = {
          sddm.enableGnomeKeyring = true;
          login.enableGnomeKeyring = true;
        };
      };

      environment.variables.XDG_RUNTIME_DIR = "/run/user/$UID"; # set the runtime directory so keyring is unlocked on login
      services = {
        gnome.gnome-keyring.enable = true;
        gvfs.enable = true; # Mount, trash, and other functionalities
        tumbler.enable = true; # Thumbnails
        dbus = {
          enable = true;
          implementation = "broker";
        };
        upower.enable = true;
        xserver = {
          enable = true;
        };
        displayManager.gdm.enable = lib.mkDefault true;
      };

      xdg = {
        menus.enable = true;
        portal = {
          enable = true;
          wlr.enable = true;
          extraPortals = [inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland];

          config.hyprland = {
            default = [
              "hyprland"
            ];
            "org.freedesktop.impl.portal.FileChooser" = "hyprland";
          };
        };
        mime = {
          enable = true;

          defaultApplications = {
            "x-scheme-handler/about" = "zen.desktop";
            "x-scheme-handler/unknown" = "zen.desktop";
            "x-scheme-handler/http" = "zen.desktop";
            "x-scheme-handler/https" = "zen.desktop";
            # PDF
            "application/pdf" = "org.gnome.Evince.desktop";
            # PNG, JPG
            "image/png" = "org.gnome.Loupe.desktop";
            "image/jpeg" = "org.gnome.Loupe.desktop";
            "image/ppm" = "org.gnome.Loupe.desktop";
            # Text
            "text/javascript" = lib.mkDefault "nvim.desktop";
            "text/rust" = lib.mkDefault "nvim.desktop";
            "text/x-python" = lib.mkDefault "nvim.desktop";
            "text/x-java-source" = lib.mkDefault "nvim.desktop";
            "text/x-c" = lib.mkDefault "nvim.desktop";
            "text/x-go" = lib.mkDefault "nvim.desktop";
            "text/x-nix" = lib.mkDefault "nvim.desktop";
            "text/x-ocaml" = lib.mkDefault "nvim.desktop";
            "text/x-scala" = lib.mkDefault "nvim.desktop";
            "text/x-tex" = lib.mkDefault "nvim.desktop";
            "text/x-matlab" = lib.mkDefault "nvim.desktop";
            "text/x-meson" = lib.mkDefault "nvim.desktop";
            "text/x-dart" = lib.mkDefault "nvim.desktop";
            "text/x-readme" = lib.mkDefault "nvim.desktop";
            "text/x-sh" = lib.mkDefault "nvim.desktop";
            "text/x-nushell" = lib.mkDefault "nvim.desktop";
            "text/html" = lib.mkDefault "zen.desktop";
            # Directories
            "inode/directory" = "org.kde.dolphin.desktop";
            "x-scheme-handler/file" = "org.kde.dolphin.desktop";
            "application/octet-stream" = "org.kde.dolphin.desktop";
            # .txt
            "text/plain" = "nvim.desktop";
          };
        };
      };
    };
  }
