{
  description = "Conner Ohnesorge's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:conneroisu/zen-browser-flake/master";

    stylix.url = "github:danth/stylix";
    hyprwm-qtutils = {
      url = "github:hyprwm/hyprland-qtutils"; # Note: correct repo name
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
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    zen-browser,
    nix-ld,
    stylix,
    darwin,
    nix-homebrew,
    nixos-hardware,
    hyprwm-qtutils,
    ...
  } @ inputs: let
    systems = {
      x86_64-linux = "x86_64-linux";
      aarch64-linux = "aarch64-linux";
      x86_64-darwin = "x86_64-darwin";
      aarch64-darwin = "aarch64-darwin";
    };
  in {
    nixosConfigurations = {
      xps-nixos = nixpkgs.lib.nixosSystem {
        system = systems.x86_64-linux;
        specialArgs = {
          pkgs = import nixpkgs {
            hostPlatform = systems.x86_64-linux;
            system = systems.x86_64-linux;
            config.allowUnfree = true;
          };
          unstable-pkgs = import nixpkgs-unstable {
            hostPlatform = systems.x86_64-linux;
            system = systems.x86_64-linux;
            config.allowUnfree = true;
          };
          inherit self stylix zen-browser hyprwm-qtutils;
        };
        modules = [
          nixos-hardware.nixosModules.dell-xps-15-9510
          stylix.nixosModules.stylix
          nix-ld.nixosModules.nix-ld
          {programs.nix-ld.dev.enable = true;}
          ./hosts/Shared
          ./hosts/xps-nixos
        ];
      };
    };

    darwinConfigurations = {
      "Conners-MacBook-Air" = darwin.lib.darwinSystem {
        system = systems.aarch64-darwin;
        specialArgs = {
          pkgs = import nixpkgs {
            system = systems.aarch64-darwin;
            hostPlatform = systems.aarch64-darwin;
            config.allowUnfree = true;
          };
          unstable-pkgs = import nixpkgs-unstable {
            system = systems.aarch64-darwin;
            hostPlatform = systems.aarch64-darwin;
            config.allowUnfree = true;
          };
          inherit self zen-browser;
          inherit
            (inputs)
            homebrew-core
            homebrew-cask
            homebrew-bundle
            ;
        };
        modules = [
          nix-homebrew.darwinModules.nix-homebrew
          ./hosts/Shared
          ./hosts/aarch64-darwin
        ];
      };
    };
  };
}
