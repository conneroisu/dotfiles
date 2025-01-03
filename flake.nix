{
  description = "Conner Ohnesorge's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:conneroisu/zen-browser-flake?tag=v0.1.0";

    stylix.url = "github:danth/stylix";

    hyprwm-qtutils = {
      url = "github:hyprwm/hyprland-qtutils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty.url = "github:ghostty-org/ghostty/main";

    sops-nix.url = "github:Mic92/sops-nix";

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    homebrew-core.url = "github:Homebrew/homebrew-core";
    homebrew-core.flake = false;

    homebrew-cask.url = "github:Homebrew/homebrew-cask";
    homebrew-bundle.url = "github:Homebrew/homebrew-bundle";

    homebrew-cask.flake = false;
    homebrew-bundle.flake = false;

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: let
    inherit (inputs) snowfall-lib;
    lib = snowfall-lib.mkLib {
      inherit inputs;
      inherit (inputs) stylix nix-darwin homebrew-core homebrew-cask homebrew-bundle disko;
      src = ./.;

      snowfall = {
        namespace = "csnow";
        meta = {
          name = "conneroisu-snow";
          title = "Conner Ohnesorge's Snowflake";
        };
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
          ./modules/shared
          home-manager.nixosModules.home-manager
          stylix.nixosModules.stylix
          nix-ld.nixosModules.nix-ld
          {programs.nix-ld.dev.enable = true;}
          sops-nix.nixosModules.default
          {
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
          }
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];

        # Add modules to all Darwin systems.
        darwin = with inputs; [
          ./modules/shared
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          sops-nix.darwinModules.default
          {
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
          }
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };

      outputs-builder = channels: {
        formatter = channels.nixpkgs.alejandra;
      };
    };
}
