/**
# Feature Module: KDE Plasma Desktop Environment

## Description
Complete KDE Plasma 6 desktop environment with comprehensive Wayland support,
integrated theming via Stylix, and a curated suite of KDE applications optimized
for productivity and development workflows.

## Platform Support
- ✅ NixOS (Full desktop environment)
- ❌ Darwin (KDE Plasma is Linux-only)

## What This Enables
### Core Desktop
- **KDE Plasma 6**: Wayland-first desktop with SDDM
- **Window Management**: KWin compositor with effects and tiling
- **Activities & Workspaces**: Multi-desktop organization
- **Panels & Widgets**: Customizable desktop layout

### Application Suite
- **Core Tools**: Dolphin, Kate, Konsole, Spectacle
- **Productivity**: Okular, Ark, KCalc, KRunner
- **Media**: Elisa, Gwenview, Dragon Player
- **Development**: KDevelop, Kompare, Umbrello
- **Communication**: Kontact, KMail, KDE Connect

### System Integration
- **Theming**: Automatic Stylix integration via Qt
- **Hardware**: Audio (PipeWire), Bluetooth, Network
- **Services**: Printing, Location, Power management
- **Security**: Polkit, KWallet, PAM integration

## Stylix Integration
KDE theming works automatically when `stylix.targets.qt.enable = true`
is set in your rice configuration. All Qt/KDE applications inherit
the Base16 color scheme through Qt theming.
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
    name = "features.kde";
    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = let
        # Core KDE Plasma packages
        coreDesktop = with pkgs.kdePackages; [
          plasma-desktop
          plasma-workspace
          plasma-workspace-wallpapers
          kwin
          systemsettings
          krunner
          kglobalaccel
        ];

        # Essential applications
        coreApps = with pkgs.kdePackages; [
          dolphin
          dolphin-plugins
          konsole
          kate
          spectacle
          okular
          gwenview
          ark
          kcalc
        ];

        # File system and I/O
        fileSystem = with pkgs.kdePackages; [
          kio
          kio-extras
          kio-fuse
          baloo
          baloo-widgets
        ];

        # Media and multimedia
        mediaApps = with pkgs.kdePackages; [
          elisa
          dragon
          k3b
        ];

        # Communication and PIM
        communicationApps = with pkgs.kdePackages; [
          kontact
          kmail
          kaddressbook
          korganizer
          kdeconnect-kde
        ];

        # Development tools
        devTools = with pkgs.kdePackages; [
          kdevelop
          kompare
        ];

        # System integration
        systemIntegration = with pkgs.kdePackages; [
          discover
          powerdevil
          plasma-browser-integration
          plasma-thunderbolt
          plasma-nm
          bluedevil
          print-manager
        ];

        # Themes and appearance
        themes = with pkgs.kdePackages; [
          breeze
          breeze-icons
          breeze-gtk
          oxygen
          oxygen-icons
        ];

        # Security and wallet
        security = with pkgs.kdePackages; [
          kwallet
          kwallet-pam
          kwalletmanager
          ksshaskpass
        ];

        # Utilities
        utilities = with pkgs.kdePackages; [
          filelight
          kcharselect
          kcolorchooser
          kfind
          ktimer
          kruler
        ];

        # Optional games
        games = with pkgs.kdePackages; [
          kmahjongg
          kpat
        ];

        # Third-party applications with good KDE integration
        thirdParty = with pkgs; [
          firefox
          vlc
          libreoffice-qt
          gimp
          inkscape
          audacity
          obs-studio
          qt6ct
        ];
      in
        coreDesktop
        ++ coreApps
        ++ fileSystem
        ++ mediaApps
        ++ communicationApps
        ++ devTools
        ++ systemIntegration
        ++ themes ++ security ++ utilities ++ games ++ thirdParty;

      environment = {
        variables = {
          # Session and desktop identification
          XDG_SESSION_TYPE = "wayland";
          XDG_SESSION_DESKTOP = lib.mkDefault "KDE";
          XDG_CURRENT_DESKTOP = lib.mkDefault "KDE";
          KDE_SESSION_VERSION = "6";
          KDE_FULL_SESSION = "true";

          # Qt/Wayland configuration
          QT_QPA_PLATFORM = lib.mkDefault "wayland;xcb";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          QT_AUTO_SCREEN_SCALE_FACTOR = "1";
          QT_SCALE_FACTOR_ROUNDING_POLICY = "RoundPreferFloor";

          # Theme integration (overridden by Stylix when active)
          GTK_THEME = lib.mkDefault "Breeze";

          # Input method configuration
          GTK_IM_MODULE = "fcitx";
          QT_IM_MODULE = "fcitx";
          XMODIFIERS = "@im=fcitx";
        };

        # Plasma locale configuration
        etc."xdg/plasma-localerc".text = ''
          [Formats]
          LANG=en_US.UTF-8
        '';
      };

      # Essential programs
      programs = {
        dconf.enable = true;
        kdeconnect.enable = true;
        partition-manager.enable = true;
      };

      # System services configuration
      services = {
        # Desktop environment
        desktopManager.plasma6.enable = true;
        displayManager = {
          sddm = {
            enable = true;
            wayland.enable = true;
            theme = "breeze";
            autoNumlock = true;
          };
          gdm.enable = lib.mkForce false;
        };

        # Core system services
        dbus.enable = true;
        udisks2.enable = true;
        upower.enable = true;
        accounts-daemon.enable = true;

        # Audio stack
        pipewire = {
          enable = true;
          pulse.enable = true;
          alsa.enable = true;
          jack.enable = true;
        };

        # Connectivity
        blueman.enable = true;

        # Printing and discovery
        printing.enable = true;
        avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };

        # Hardware and power
        fwupd.enable = true;
        thermald.enable = true;
        power-profiles-daemon.enable = false;

        # File system services
        gvfs.enable = true;
        tumbler.enable = true;

        # Additional services
        geoclue2.enable = true;
      };

      # Input method configuration
      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
          waylandFrontend = true;
          addons = with pkgs; [
            fcitx5-gtk
          ];
        };
      };

      # XDG configuration
      xdg = {
        portal = {
          enable = true;
          extraPortals = [
            pkgs.kdePackages.xdg-desktop-portal-kde
            pkgs.xdg-desktop-portal-gtk
          ];
          config = {
            common.default = ["kde"];
            kde = {
              default = ["kde" "gtk"];
              "org.freedesktop.impl.portal.FileChooser" = ["kde"];
              "org.freedesktop.impl.portal.AppChooser" = ["kde"];
              "org.freedesktop.impl.portal.Print" = ["kde"];
              "org.freedesktop.impl.portal.Notification" = ["kde"];
            };
          };
        };

        # Default applications
        mime = {
          enable = true;
          defaultApplications = {
            # Web
            "x-scheme-handler/about" = lib.mkDefault "zen.desktop";
            "x-scheme-handler/unknown" = lib.mkDefault "zen.desktop";
            "x-scheme-handler/http" = lib.mkDefault "zen.desktop";
            "x-scheme-handler/https" = lib.mkDefault "zen.desktop";
            # FS
            "inode/directory" = lib.mkDefault "org.kde.dolphin.desktop";
            # Files
            "text/calendar" = lib.mkDefault "org.kde.korganizer.desktop";
            "text/html" = lib.mkDefault "zen.desktop";
            # Images
            "image/jpeg" = lib.mkDefault "org.kde.gwenview.desktop";
            "image/png" = lib.mkDefault "org.kde.gwenview.desktop";
            # Documents
            "application/pdf" = lib.mkDefault "org.kde.okular.desktop";
            # Audio
            "audio/mpeg" = lib.mkDefault "org.kde.elisa.desktop";
            # Video
            "video/mp4" = lib.mkDefault "vlc.desktop";
            # Archives
            "application/zip" = lib.mkDefault "org.kde.ark.desktop";
          };
        };
      };

      # Security configuration
      security = {
        polkit.enable = true;
        rtkit.enable = true;
        pam.services = {
          sddm.enableGnomeKeyring = true;
          sddm-autologin.enableGnomeKeyring = true;
        };
      };

      # Hardware configuration
      hardware = {
        enableAllFirmware = true;
        bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings.General = {
            Enable = "Source,Sink,Media,Socket";
            Experimental = "true";
          };
        };
      };

      # System services
      systemd.user.services.plasma-localed = {
        description = "Plasma localed proxy";
        wantedBy = ["graphical-session.target"];
        serviceConfig = {
          ExecStart = "${pkgs.kdePackages.plasma-workspace}/libexec/plasma-localed";
          Restart = "on-failure";
        };
      };

      # Font configuration
      fonts = {
        enableDefaultPackages = true;
        packages = with pkgs; [
          # Primary fonts
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-emoji
          fira-code
          fira-code-symbols
          # Development fonts
          source-code-pro
          source-sans-pro
          source-serif-pro
          # System fonts
          liberation_ttf
          ubuntu_font_family
          cantarell-fonts
          # Specialized fonts
          mplus-outline-fonts.githubRelease
          dina-font
          proggyfonts
        ];

        fontconfig = {
          enable = true;
          defaultFonts = {
            monospace = ["Fira Code" "Source Code Pro"];
            sansSerif = ["Noto Sans" "Source Sans Pro"];
            serif = ["Noto Serif" "Source Serif Pro"];
            emoji = ["Noto Color Emoji"];
          };
        };
      };
    };

    home.ifEnabled = {
      # KDE application configurations
      # Note: KDE-specific Home Manager program modules don't exist in current nixpkgs
      # These applications are installed via system packages above
      # programs = {
      #   # Text editor with LSP support
      #   kate = {
      #     enable = true;
      #   };
      #
      #   # Terminal emulator
      #   konsole = {
      #     enable = true;
      #   };
      #
      #   # Document viewer
      #   okular = {
      #     enable = true;
      #   };
      #
      #   # Music player
      #   elisa = {
      #     enable = true;
      #   };
      #
      #   # Markdown editor
      #   ghostwriter = {
      #     enable = true;
      #   };
      # };

      # Additional KDE packages for Home Manager
      home.packages = with pkgs.kdePackages; [
        # Extra utilities
        filelight
        kcharselect
        kcolorchooser
        kruler
        ktimer
        kfind
        # Plasma addons
        kdeplasma-addons
        plasma-browser-integration
        # Development tools
        kdevelop
        kompare
        # Optional games
        kmahjongg
        kpat
      ];
    };
  }
