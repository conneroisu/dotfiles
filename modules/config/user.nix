{
  delib,
  pkgs,
  ...
}: let
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKkl3bfwNy75UX9kAGk9WLMTVW0lKKZ8r4OV36VRcd42 connerohnesorge@xps-nixos"
  ];
in
  delib.module {
    name = "connerohnesorge";

    # macOS (Darwin) user configuration
    darwin.always = {myconfig, ...}: let
      inherit (myconfig.constants) username;
    in {
      # Nix daemon configuration for macOS
      nix = {
        settings = {
          # Enable modern Nix features
          lazy-trees = true;
          experimental-features = [
            "nix-command" # New nix CLI commands
            "flakes" # Nix flakes support
          ];

          # Users allowed to perform privileged Nix operations
          trusted-users = [
            "root"
            "@wheel" # All wheel group members
            "connerohnesorge"
          ];

          # Users allowed to use Nix daemon
          allowed-users = [
            "root"
            "@wheel"
            "connerohnesorge"
          ];

          # Binary cache configuration for faster builds
          substituters = [
            "https://cache.nixos.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          ];
        };
      };

      # User and group creation
      users = {
        groups.${username} = {};
        users.${username} = {
          home = "/Users/${username}"; # macOS home directory convention
        };
      };
    };

    # NixOS user configuration with full system integration
    nixos.always = {myconfig, ...}: let
      inherit (myconfig.constants) username;
    in {
      # NixOS Nix daemon configuration (forced to override defaults)
      nix = pkgs.lib.mkForce {
        settings = {
          # Performance optimizations
          max-jobs = 8; # Parallel build jobs
          lazy-trees = true; # Lazy evaluation for better performance

          # Enable modern Nix features
          experimental-features = [
            "nix-command"
            "flakes"
          ];

          # Privileged user configuration
          trusted-users = [
            "root"
            "@wheel"
            "${myconfig.constants.username}"
          ];

          # Allowed user configuration
          allowed-users = [
            "root"
            "@wheel"
            "${myconfig.constants.username}"
          ];

          # Binary cache for faster package installation
          substituters = [
            "https://cache.nixos.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          ];
        };
      };

      # User and group management
      users = {
        # Create user's primary group
        groups.${username} = {};

        # Create NordVPN group for VPN access
        groups.nordvpn = {};

        # Main user account configuration
        users.${username} = {
          home = "/home/${username}"; # Linux home directory convention
          isNormalUser = true; # Standard user (not system account)

          # System group memberships for required services
          extraGroups = [
            "networkmanager" # Network configuration access
            "wheel" # Sudo privileges
            "docker" # Docker daemon access
            "users" # Standard users group
            "nordvpn" # VPN access
          ];

          # SSH public key for remote access
          openssh.authorizedKeys = {
            inherit keys;
          };

          # Set default shell to zsh
          shell = pkgs.zsh;
        };
        users.root = pkgs.lib.mkDefault {
          home = "/root";
          isNormalUser = true;
          openssh.authorizedKeys = {
            inherit keys;
          };
        };
      };

      # Note: Custom nix.conf generation is available but currently disabled
      # The commented section below shows how to generate custom nix configuration
      # if needed for specialized setups
      # environment = {
      #   etc."nix/nix.custom.conf".text = let
      #     # This function converts an attribute set to Nix configuration lines
      #     settingsToConf = settings:
      #       pkgs.lib.concatStringsSep "\n" (
      #         pkgs.lib.mapAttrsToList (
      #           name: value: "${name} = ${
      #             if builtins.isBool value
      #             then pkgs.lib.boolToString value
      #             else if builtins.isInt value
      #             then toString value
      #             else if builtins.isList value
      #             then pkgs.lib.concatMapStringsSep " " (x: "${toString x}") value
      #             else if builtins.isString value
      #             then value
      #             else throw "Unsupported type for nix.conf setting ${name}"
      #           }"
      #         )
      #         settings
      #       );
      #   in
      #     # Apply the function to your desired settings
      #     settingsToConf {
      #       # Add your nix settings here, for example:
      #       max-jobs = 8;
      #       experimental-features = [
      #         "nix-command"
      #         "flakes"
      #       ];
      #       trusted-users = [
      #         "root"
      #         "@wheel"
      #         "connerohnesorge"
      #       ];
      #       allowed-users = [
      #         "root"
      #         "@wheel"
      #         "connerohnesorge"
      #       ];
      #     };
      # };
    };
  }
