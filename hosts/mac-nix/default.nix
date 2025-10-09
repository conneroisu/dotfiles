/**
# Host Configuration: mac-nix (Conner's MacBook Air)

## Description
Primary development machine configuration for macOS (Apple Silicon).
This host runs nix-darwin for package management.

## Host Type
- Type: laptop
- System: aarch64-darwin (Apple Silicon)
- Rice: dark theme

## Key Features
- **Engineer role**: Development tools and environments
- **macOS integration**: Native macOS apps (Aerospace, Raycast, Xcodes)
- **Blink shell**: Terminal emulator with fuzzy search

## Platform-specific Configurations
### Darwin
- Touch ID for sudo authentication
- Custom dock and trackpad settings
- Nix Apps integration in /Applications
- Container support via gvproxy

## Enabled Programs
- dx: Flake.nix editor
- catls: Ruby-based file browser
- convert_img: Image conversion utility
*/
{
  delib,
  inputs,
  pkgs,
  config,
  lib,
  ...
}: let
  system = "aarch64-darwin";
in
  delib.host {
    name = "Conners-MacBook-Air";
    rice = "empty";
    type = "laptop";

    home.home.stateVersion = "24.11";
    homeManagerSystem = system;

    myconfig = {
      features = {
        engineer.enable = true;
      };
      programs = {
        dx.enable = true;
        catls.enable = true;
        convert_img.enable = true;
      };
    };

    nixos = {
      imports = [
        inputs.determinate.nixosModules.default
      ];
      nixpkgs.hostPlatform = "x86_64-linux";
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.allowUnsupportedSystem = true;
      system.stateVersion = "24.11";

      # Minimal file system configuration to prevent assertion failures
      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    };

    darwin = {
      imports = [
        # inputs.determinate.darwinModules.default
      ];

      nixpkgs = {
        hostPlatform = system;
        config.allowUnfree = true;
      };
      nix.enable = false;
      # $ nix-env -qaP | grep wget
      programs = {
        direnv = {
          enable = true;
          nix-direnv = {
            enable = true;
            package = pkgs.nix-direnv;
          };
        };
        ssh = {
          extraConfig = ''
            SetEnv TERM=xterm-256color
          '';
        };
      };
      system = {
        stateVersion = 5;
        primaryUser = "connerohnesorge";
        defaults = {
          dock.autohide = true;

          trackpad = {
            Clicking = true;
            TrackpadThreeFingerDrag = true;
            Dragging = true;
          };
        };
      };

      environment = {
        systemPackages =
          [
            # Macos Only
            pkgs.aerospace
            pkgs.raycast
            pkgs.xcodes
            # Shared
          ]
          ++ [
            inputs.blink.packages."${system}".default
            inputs.blink.packages."${system}".blink-fuzzy-lib
          ];
        shells = [pkgs.zsh];

        pathsToLink = ["/share/qemu"];
        etc."containers/containers.conf.d/99-gvproxy-path.conf".text = ''
          [engine]
          helper_binaries_dir = ["${pkgs.gvproxy}/bin"]
        '';
      };
      users.users.connerohnesorge = {
        home = "/Users/connerohnesorge";
      };

      security.pam.services.sudo_local.touchIdAuth = true;
      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        lib.mkForce ''
          # Set up applications.
          echo "setting up /Applications..." >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
          while read -r src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';
    };
  }
