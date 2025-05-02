{
  description = "Conner Ohnesorge's dotfiles";

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    systems.url = "github:nix-systems/default";

    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/0.1.5";

    hyprland.url = "https://flakehub.com/f/hyprwm/Hyprland/0.48.1";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "https://flakehub.com/f/hercules-ci/flake-parts/0.1.372";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    flake-utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    flake-utils.inputs.systems.follows = "systems";

    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";

    snowfall-lib.url = "https://flakehub.com/f/snowfallorg/lib/3.0.3";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "https://flakehub.com/f/nix-community/home-manager/0.2411.*";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    nix-homebrew.inputs.nixpkgs.follows = "nixpkgs";

    homebrew-core.url = "github:Homebrew/homebrew-core";
    homebrew-core.flake = false;
    homebrew-cask.url = "github:Homebrew/homebrew-cask";
    homebrew-cask.flake = false;

    ashell.url = "https://flakehub.com/f/conneroisu/ashell/0.1.481";
    ashell.inputs = {
      nixpkgs.follows = "nixpkgs";
      rust-overlay.follows = "rust-overlay";
    };

    nh.url = "github:viperML/nh/master?tag=v4.0.0-beta.8";
    nh.inputs.nixpkgs.follows = "nixpkgs";

    snowfall-flake.url = "https://flakehub.com/f/snowfallorg/flake/1.4.1";
    snowfall-flake.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "https://flakehub.com/f/oxalica/rust-overlay/0.1.1771";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:conneroisu/zen-browser-flake?tag=v1.11.5b";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "https://flakehub.com/f/danth/stylix/0.1.776";
    stylix.inputs = {
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
      home-manager.follows = "home-manager";
      flake-utils.follows = "flake-utils";
    };

    ghostty.url = "github:ghostty-org/ghostty/main";
    ghostty.inputs = {
      nixpkgs-unstable.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
    };

    coder.url = "github:coder/coder/v2.20.3";
    coder.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
    };

    blink.url = "github:Saghen/blink.cmp";
    blink.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-parts.follows = "flake-parts";
    };
  };

  outputs = inputs @ {
    flake-parts,
    self,
    flake-schemas,
    home-manager,
    ...
  }: let
    inherit (self) outputs;
    stateVersion = "24.11";
    helper = import ./home-manager/utils {inherit inputs outputs stateVersion;};
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = _: {};
      flake = let
        inherit (inputs) snowfall-lib;
        lib = snowfall-lib.mkLib {
          inherit inputs;
          src = ./.;

          snowfall = {
            namespace = "csnow";
            meta = {
              name = "csnow";
              title = "Conner Ohnesorge's Snowflake";
            };
          };
        };

        config = {
          nix.settings = {
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            trusted-users = [
              "root"
              "connerohnesorge"
              "@wheel"
            ];
            allowed-users = [
              "root"
              "connerohnesorge"
              "@wheel"
            ];
          };
        };
      in
        lib.mkFlake {
          inherit inputs;
          src = ./.;
          channels-config = {
            allowUnfree = true;
          };
          systems.modules = {
            # Add modules to all NixOS systems.
            nixos = with inputs; [
              determinate.nixosModules.default
              ./modules/shared
              home-manager.nixosModules.home-manager
              stylix.nixosModules.stylix
              nix-ld.nixosModules.nix-ld
              {programs.nix-ld.dev.enable = true;}
              config
            ];

            # Add modules to all Darwin systems.
            darwin = with inputs; [
              ./modules/shared
              nix-homebrew.darwinModules.nix-homebrew
              home-manager.darwinModules.home-manager
              config
            ];
          };
          outputs-builder = channels: {
            formatter = channels.nixpkgs.alejandra;
          };
        }
        // {
          homeConfigurations = {
            "connerohnesorge@Conners-MacBook-Air.local" = helper.mkHome {
              username = "connerohnesorge";
              hostname = "Conners-MacBook-Air.local";
              platform = "aarch64-darwin";
            };
            "connerohnesorge@xps-nixos" = helper.mkHome {
              username = "connerohnesorge";
              hostname = "xps-nixos";
              platform = "x86_64-linux";
            };
          };
        };
    }
    // {inherit (flake-schemas) schemas;};
}
