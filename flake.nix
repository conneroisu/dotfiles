{
  description = "Conner Ohnesorge's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
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

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nix-ld,
    nixos-hardware,
    stylix,
    home-manager,
    darwin,
    nix-homebrew,
    homebrew-core,
    homebrew-cask,
    homebrew-bundle,
    ...
  }: let
    systems = {
      x86_64-linux = "x86_64-linux";
      aarch64-darwin = "aarch64-darwin";
    };
    
    pkgs = import nixpkgs {
      system = systems.x86_64-linux;
      config = {
        allowUnfree = true;
      };
    };
    
    darwinPkgs = import nixpkgs {
      system = systems.aarch64-darwin;
      config = {
        allowUnfree = true;
      };
    };
    
    unstable-pkgs = import nixpkgs-unstable {
      system = systems.x86_64-linux;
      config = {
        allowUnfree = true;
      };
    };
  in {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit (systems) x86_64-linux;
          inherit pkgs unstable-pkgs inputs stylix self;
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
      "Conners-MacBook-Air" = darwin.lib.darwinSystem {
        system = systems.aarch64-darwin;
        specialArgs = {
          inherit (systems) aarch64-darwin;
          inherit inputs self darwinPkgs unstable-pkgs;
        };
        modules = [
          ./hosts/aarch64-darwin
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs self darwinPkgs;
              };
            };
          }
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
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