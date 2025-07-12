# home.nix - Base Home Manager Configuration Module
#
# This module provides the foundational Home Manager configuration that applies
# to all systems regardless of platform. It handles cross-platform differences
# and sets up essential user environment settings.
#
# Key responsibilities:
# - Cross-platform home directory configuration
# - GTK theming (Linux-only)
# - Base system utilities and fetch tools
# - Essential environment variables
# - Home Manager service configurations
#
# Platform-specific behavior:
# - Linux: Enables GTK theming with dark theme preference
# - macOS: Uses /Users/ path convention and includes m-cli
# - Both: Provides consistent editor and fetch tool experience

{
  delib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin isLinux;
in
  delib.module {
    name = "home";

    home.always = {myconfig, ...}: let
      inherit (myconfig.constants) username;
    in {
      # GTK theming configuration (Linux only)
      # Provides a consistent dark theme across GTK applications
      gtk =
        if isLinux
        then {
          enable = true;
          theme = {
            name = pkgs.lib.mkForce "adw-gtk3-dark";
            package = pkgs.lib.mkForce pkgs.adw-gtk3;
          };
          iconTheme.package = pkgs.papirus-icon-theme;
          iconTheme.name = "Papirus";

          # Force dark theme preference for GTK3 applications
          gtk3.extraConfig = {
            Settings = ''
              gtk-application-prefer-dark-theme=1
            '';
          };

          # Force dark theme preference for GTK4 applications
          gtk4.extraConfig = {
            Settings = ''
              gtk-application-prefer-dark-theme=1
            '';
          };
        }
        else {};

      # Workaround for home-manager news notification bug
      # See: https://github.com/nix-community/home-manager/issues/2033
      news = {
        display = "silent";
        entries = pkgs.lib.mkForce [];
      };

      # Enable home-manager to manage itself
      programs.home-manager.enable = true;

      # MPRIS proxy service for media key support (Linux only)
      services.mpris-proxy.enable =
        if isLinux
        then true
        else false;
        
      home = {
        # Set username from constants
        inherit username;
        
        # Platform-specific home directory paths
        homeDirectory =
          if isDarwin
          then "/Users/${username}"
          else "/home/${username}";

        # Base system utility packages
        # Fetch tools for system information display
        packages = with pkgs;
          [
            cpufetch    # CPU information fetcher
            fastfetch   # Fast system information display
            ipfetch     # IP and network information
            onefetch    # Git repository information
          ]
          # Linux-specific packages
          ++ lib.optionals isLinux [
            ramfetch    # RAM usage information
          ]
          # macOS-specific packages  
          ++ lib.optionals isDarwin [
            m-cli       # macOS command line tools
          ];
          
        # Essential environment variables for consistent editor experience
        sessionVariables = {
          EDITOR = "nvim";        # Default text editor
          SYSTEMD_EDITOR = "nvim"; # Editor for systemd operations
          VISUAL = "nvim";        # Visual editor for applications
          MANPAGER = "nvim +Man!"; # Manpage viewer
        };
      };
    };
  }
