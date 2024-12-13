{
  description = "Conner Ohnesorge's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:Conneroisu/zen-browser-flake/master";

    stylix.url = "github:danth/stylix";

    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    homebrew-core.url = "github:Homebrew/homebrew-core";
    homebrew-core.flake = false;

    homebrew-cask.url = "github:Homebrew/homebrew-cask";
    homebrew-bundle.url = "github:Homebrew/homebrew-bundle";

    homebrew-cask.flake = false;
    homebrew-bundle.flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    zen-browser,
    nix-ld,
    stylix,
    darwin,
    nix-homebrew,
    nixos-hardware,
    ...
  } @ inputs: let
    systems = {
      x86_64-linux = "x86_64-linux";
      x86_64-darwin = "x86_64-darwin";
      aarch64-linux = "aarch64-linux";
      aarch64-darwin = "aarch64-darwin";
    };
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = systems.x86_64-linux;
      specialArgs = {
        pkgs = import nixpkgs {
          system = systems.x86_64-linux;
          config = {allowUnfree = true;};
        };
        unstable-pkgs = import nixpkgs-unstable {
          system = systems.x86_64-linux;
          config = {allowUnfree = true;};
        };
        inherit self home-manager stylix zen-browser;
      };
      modules = [
        home-manager.nixosModules.home-manager
        nixos-hardware.nixosModules.dell-xps-15-9510
        stylix.nixosModules.stylix
        nix-ld.nixosModules.nix-ld
        ./hosts/Shared
        ./hosts/x86_64-nixos
      ];
    };

    darwinConfigurations."Conners-MacBook-Air" = darwin.lib.darwinSystem {
      system = systems.aarch64-darwin;
      specialArgs = {
        pkgs = import nixpkgs {
          system = systems.aarch64-darwin;
          config = {allowUnfree = true;};
        };
        unstable-pkgs = import nixpkgs-unstable {
          system = systems.aarch64-darwin;
          config = {allowUnfree = true;};
        };
        inherit self;
        inherit
          (inputs)
          homebrew-core
          homebrew-cask
          homebrew-bundle
          zen-browser
          ;
      };
      modules = [
        home-manager.darwinModules.home-manager
        nix-homebrew.darwinModules.nix-homebrew
        ./hosts/Shared
        ./hosts/aarch64-darwin
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.connerohnesorge = import ./home.nix;
          };
        }
      ];
    };
  };
}
