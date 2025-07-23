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
          plasma-desktop plasma-workspace plasma-workspace-wallpapers
          kwin systemsettings krunner kglobalaccel
        ];
        
        # Essential applications
        coreApps = with pkgs.kdePackages; [
          dolphin dolphin-plugins konsole kate spectacle
          okular gwenview ark kcalc
        ];
        
        # File system and I/O
        fileSystem = with pkgs.kdePackages; [
          kio kio-extras kio-fuse baloo baloo-widgets
        ];
        
        # Media and multimedia
        mediaApps = with pkgs.kdePackages; [
          elisa dragon kamoso k3b
          phonon phonon-backend-vlc
        ];
        
        # Communication and PIM
        communicationApps = with pkgs.kdePackages; [
          kontact kmail kaddressbook korganizer
          kdeconnect-kde
        ];
        
        # Development tools
        devTools = with pkgs.kdePackages; [
          kdevelop kompare umbrello
        ];
        
        # System integration
        systemIntegration = with pkgs.kdePackages; [
          discover powerdevil partition-manager
          plasma-browser-integration plasma-thunderbolt
          plasma-nm bluedevil print-manager
        ];
        
        # Themes and appearance
        themes = with pkgs.kdePackages; [
          breeze breeze-icons breeze-gtk
          oxygen oxygen-icons plasma-theme-oxygen
        ];
        
        # Security and wallet
        security = with pkgs.kdePackages; [
          kwallet kwallet-pam kwalletmanager ksshaskpass
        ];
        
        # Utilities
        utilities = with pkgs.kdePackages; [
          filelight kcharselect kcolorchooser kfind
          ktimer kruler kwrite
        ];
        
        # Optional games
        games = with pkgs.kdePackages; [
          kmahjongg kpat
        ];
        
        # Third-party applications with good KDE integration
        thirdParty = with pkgs; [
          firefox vlc libreoffice-qt
          gimp inkscape audacity obs-studio
        ];
      in
        coreDesktop ++ coreApps ++ fileSystem ++ mediaApps
        ++ communicationApps ++ devTools ++ systemIntegration
        ++ themes ++ security ++ utilities ++ games ++ thirdParty;

      environment.variables = {
        # Session and desktop identification
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "KDE";
        XDG_CURRENT_DESKTOP = "KDE";
        KDE_SESSION_VERSION = "6";
        KDE_FULL_SESSION = "true";
        
        # Qt/Wayland configuration
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        QT_SCALE_FACTOR_ROUNDING_POLICY = "RoundPreferFloor";
        
        # Theme integration (overridden by Stylix when active)
        GTK_THEME = "Breeze";
        
        # Input method configuration
        GTK_IM_MODULE = "fcitx";
        QT_IM_MODULE = "fcitx";
        XMODIFIERS = "@im=fcitx";
      };

      # Plasma locale configuration
      environment.etc."xdg/plasma-localerc".text = ''
        [Formats]
        LANG=en_US.UTF-8
      '';

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
        displayManager.sddm = {
          enable = true;
          wayland.enable = true;
          theme = "breeze";
          autoNumlock = true;
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
        
        # Network and connectivity
        networkmanager.enable = true;
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
        power-profiles-daemon.enable = true;
        
        # File system services
        gvfs.enable = true;
        tumbler.enable = true;
        
        # Additional services
        geoclue2.enable = true;
        fcitx5 = {
          enable = true;
          waylandFrontend = true;
        };
      };

      # XDG configuration
      xdg = {
        portal = {
          enable = true;
          extraPortals = with pkgs; [
            xdg-desktop-portal-kde
            xdg-desktop-portal-gtk
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
            "text/html" = "firefox.desktop";
            "x-scheme-handler/http" = "firefox.desktop";
            "x-scheme-handler/https" = "firefox.desktop";
            # Files
            "inode/directory" = "org.kde.dolphin.desktop";
            "text/plain" = "org.kde.kate.desktop";
            # Images
            "image/jpeg" = "org.kde.gwenview.desktop";
            "image/png" = "org.kde.gwenview.desktop";
            # Documents
            "application/pdf" = "org.kde.okular.desktop";
            # Audio/Video
            "audio/mpeg" = "org.kde.elisa.desktop";
            "video/mp4" = "vlc.desktop";
            # Archives
            "application/zip" = "org.kde.ark.desktop";
          };
        };
      };

      # Security configuration
      security = {
        polkit.enable = true;
        rtkit.enable = true;
        pam = {
          services = {
            sddm.enableGnomeKeyring = true;
            sddm-autologin.enableGnomeKeyring = true;
          };
          kwallet = {
            enable = true;
            forceRun = true;
          };
        };
      };

      # Hardware configuration
      hardware = {
        enableAllFirmware = true;
        pulseaudio.enable = false; # Using PipeWire
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
          noto-fonts noto-fonts-cjk noto-fonts-emoji
          fira-code fira-code-symbols
          # Development fonts
          source-code-pro source-sans-pro source-serif-pro
          # System fonts
          liberation_ttf ubuntu_font_family cantarell-fonts
          # Specialized fonts
          mplus-outline-fonts.githubRelease dina-font proggyfonts
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
      imports = [inputs.plasma-manager.homeManagerModules.plasma-manager];

      programs.plasma = {
        enable = true;

        # Workspace behavior
        workspace = {
          clickItemTo = "select";
          tooltipDelay = 700;
          # Theme settings managed by Stylix (fallbacks below)
          lookAndFeel = "org.kde.breezedark.desktop";
          colorScheme = "BreezeDark";
          iconTheme = "breeze-dark";
          cursorTheme = "breeze_cursors";
          wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Next/contents/images/1920x1080.jpg";
        };

        # Desktop layout
        desktop = {
          icons = {
            arrangement = "leftToRight";
            alignment = "left";
            size = 2;
            spacing = 1;
            lockInPlace = false;
          };
          mouseActions = {
            leftClick = "switchActivity";
            middleClick = "paste";
            rightClick = "contextMenu";
          };
        };

        # Panel configuration
        panels = [{
          location = "bottom";
          height = 44;
          widgets = [
            "org.kde.plasma.kickoff"
            "org.kde.plasma.pager"
            "org.kde.plasma.marginsseparator"
            {
              name = "org.kde.plasma.taskmanager";
              config.General.launchers = [
                "applications:org.kde.dolphin.desktop"
                "applications:firefox.desktop"
                "applications:org.kde.kate.desktop"
                "applications:org.kde.konsole.desktop"
              ];
            }
            "org.kde.plasma.marginsseparator"
            "org.kde.plasma.systemtray"
            "org.kde.plasma.digitalclock"
            "org.kde.plasma.showdesktop"
          ];
        }];

        # Keyboard shortcuts
        shortcuts = {
          ActivityManager = {
            "switch-to-activity-1" = "Meta+1";
            "switch-to-activity-2" = "Meta+2";
            "switch-to-activity-3" = "Meta+3";
            "switch-to-activity-4" = "Meta+4";
          };
          kwin = {
            "Switch One Desktop Down" = "Meta+Ctrl+Down";
            "Switch One Desktop Up" = "Meta+Ctrl+Up";
            "Switch One Desktop to the Left" = "Meta+Ctrl+Left";
            "Switch One Desktop to the Right" = "Meta+Ctrl+Right";
            "Window Close" = "Alt+F4";
            "Window Maximize" = "Meta+PgUp";
            "Window Minimize" = "Meta+PgDown";
            "Window Quick Tile Bottom" = "Meta+Down";
            "Window Quick Tile Left" = "Meta+Left";
            "Window Quick Tile Right" = "Meta+Right";
            "Window Quick Tile Top" = "Meta+Up";
            "ExposeAll" = "Meta+W";
            "Expose" = "Meta+E";
          };
          plasmashell."activate application launcher" = "Meta+Space";
          "org.kde.krunner.desktop"."_launch" = "Alt+Space";
          "org.kde.spectacle.desktop" = {
            "ActiveWindowScreenShot" = "Meta+Print";
            "CurrentMonitorScreenShot" = "Shift+Print";
            "FullScreenScreenShot" = "Print";
            "RectangularRegionScreenShot" = "Meta+Shift+Print";
          };
        };

        # Custom hotkeys
        hotkeys.commands = {
          terminal = { name = "Launch Terminal"; key = "Meta+Return"; command = "konsole"; };
          file-manager = { name = "Launch File Manager"; key = "Meta+F"; command = "dolphin"; };
          browser = { name = "Launch Browser"; key = "Meta+B"; command = "firefox"; };
          editor = { name = "Launch Editor"; key = "Meta+T"; command = "kate"; };
        };

        # Application launcher
        krunner = {
          position = "center";
          historyBehavior = "enableSuggestions";
          retainPriorSearch = true;
        };

        # Screen locker
        kscreenlocker = {
          autoLock = true;
          lockOnResume = true;
          passwordRequired = true;
          passwordRequiredDelay = 10;
          timeout = 10;
        };

        # Window management rules
        window-rules = [{
          description = "Firefox PiP";
          match = {
            window-class = { value = "firefox"; type = "substring"; };
            window-types = ["normal"];
          };
          apply = {
            above = { value = true; apply = "initially"; };
            desktops = { value = "\\0"; apply = "force"; };
          };
        }];

        # Plasma fonts
        fonts = {
          general = { family = "Noto Sans"; pointSize = 10; };
          fixedWidth = { family = "Fira Code"; pointSize = 10; };
          small = { family = "Noto Sans"; pointSize = 8; };
          toolbar = { family = "Noto Sans"; pointSize = 9; };
          menu = { family = "Noto Sans"; pointSize = 10; };
          windowTitle = { family = "Noto Sans"; pointSize = 10; };
        };
      };

      # KDE application configurations
      programs = {
        # Text editor with LSP support
        kate = {
          enable = true;
          lsp = {
            enable = true;
            servers = {
              bash = { command = ["bash-language-server"]; args = ["start"]; filetypes = ["sh"]; };
              nix = { command = ["nil"]; filetypes = ["nix"]; };
              python = { command = ["pylsp"]; filetypes = ["python"]; };
            };
          };
          tabBar = {
            showCloseButton = "showCloseButtonOnlyOnHover";
            expandTabs = true;
            showNewButton = true;
          };
          editor = {
            indentation = { width = 2; mode = "spaces"; };
            brackets = { automaticallyAddClosing = true; flashMatching = true; };
          };
        };

        # Terminal emulator
        konsole = {
          enable = true;
          defaultProfile = "Main";
          profiles.Main = {
            name = "Main";
            colorScheme = "Breeze";
            font = { name = "Fira Code"; size = 11; };
            cursor = { shape = "blockCursor"; color = "#ffffff"; };
            scrolling = { historySize = 10000; scrollbarPosition = "right"; };
          };
        };

        # Document viewer
        okular = {
          enable = true;
          general = { openFileInTabs = true; showOSD = true; };
        };

        # Music player
        elisa = {
          enable = true;
          indexing = {
            enable = true;
            paths = ["$HOME/Music" "$HOME/Downloads"];
          };
          interface = {
            showProgressInTaskBar = true;
            showSystemTrayIcon = true;
            alwaysUseExternalApplicationForPlaylists = false;
            forcePreferredAudioRole = true;
          };
        };

        # Markdown editor
        ghostwriter = {
          enable = true;
          displayFont = { family = "Noto Sans"; size = 12; };
          editorFont = { family = "Fira Code"; size = 11; };
          interface = {
            style = "dark";
            blockquoteStyle = 1;
            focusMode = false;
            hideMenuBarInFullScreen = true;
            showUnbreakableSpaceAs = "tilde";
            typewriterScrolling = true;
          };
          preview = {
            htmlRenderCommand = "cmark-gfm -t html";
            mathSupport = true;
          };
        };
      };

      # Additional KDE packages for Home Manager
      home.packages = with pkgs.kdePackages; [
        # Extra utilities
        kwrite filelight kcharselect kcolorchooser
        kruler ktimer kfind
        # Plasma addons
        kdeplasma-addons plasma-browser-integration
        # Development tools
        kdevelop kompare umbrello
        # Optional games
        kmahjongg kpat
      ];
    };
  }