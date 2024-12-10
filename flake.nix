{
  description = "Conner Ohnesorge's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-ld = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:Mic92/nix-ld";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:conneroisu/zen-browser-flake";
    stylix.url = "github:danth/stylix";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nix-ld,
      nixos-hardware,
      stylix,
      home-manager,
      homebrew-core,
      homebrew-cask,
      homebrew-bundle,
      ...
    }:
    let
      x86_64-linux = "x86_64-linux";
      aarch64-darwin = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit x86_64-linux;
        config = {
          allowUnfree = true;
        };
      };
      unstable-pkgs = import nixpkgs-unstable {
        inherit x86_64-linux;
        config = {
          allowUnfree = true;
        };
      };
      inherit (self) inputs;
    in
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              x86_64-linux
              pkgs
              unstable-pkgs
              inputs
              stylix
              ;
          };
          modules = [
            ./hosts/x86_64-nixos
            nixos-hardware.nixosModules.dell-xps-15-9510
            nix-ld.nixosModules.nix-ld
            { programs.nix-ld.dev.enable = true; }
            inputs.stylix.nixosModules.stylix
          ];
        };
      };
      darwinConfigurations = {
        "Conners-MacBook-Air" = nixpkgs.lib.darwinSystem {
          specialArgs = {
            inherit
              aarch64-darwin
              pkgs
              unstable-pkgs
              inputs
              stylix
              ;
          };
          modules = [
            ./hosts/aarch64-darwin
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
            {
              nix-homebrew = {
                # Install Homebrew under the default prefix
                enable = true;
                # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
                enableRosetta = true;
                user = "connerohnesorge";
                taps = {
                  "homebrew/homebrew-core" = inputs.homebrew-core;
                  "homebrew/homebrew-cask" = inputs.homebrew-cask;
                  "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
                };
                mutableTaps = false;
              };
            }
          ];
        };
      };
    };
}
