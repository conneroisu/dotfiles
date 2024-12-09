{
  description = "Conner Ohnesorge's Nix Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nix-darwin.url = "github:lnl7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    homebrew-core.url = "github:Homebrew/homebrew-core";
    homebrew-core.flake = false;
    homebrew-cask.url = "github:Homebrew/homebrew-cask";
    homebrew-cask.flake = false;
    homebrew-bundle.url = "github:Homebrew/homebrew-bundle";
    homebrew-bundle.flake = false;
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    zen-browser.url = "github:conneroisu/zen-browser-flake";
    stylix.url = "github:danth/stylix";
  };

  outputs =
    {
      nixpkgs,
      ...
    }@inputs:
    let
      user = "connerohnesorge";
    in
    {
      nixosConfigurations = {
        nixos = inputs.nixpkgs.lib.nixosSystem {
          specialArgs = inputs;
          modules = [
            inputs.nixos-hardware.nixosModules.dell-xps-15-9510
            inputs.nix-ld.nixosModules.nix-ld
            { programs.nix-ld.dev.enable = true; }
            inputs.stylix.nixosModules.stylix
            ./hosts/nixos
          ];
        };
      };
      darwinConfigurations = {
        "Conners-MacBook-Air" = inputs.nix-darwin.lib.darwinSystem {
          inherit (inputs.nixpkgs) system;
          specialArgs = inputs;
          modules = [
            inputs.home-manager.darwinModules.home-manager
            inputs.nix-homebrew.darwinModules.nix-homebrew
            ./hosts/darwin
          ];
        };
      };
    };
}
