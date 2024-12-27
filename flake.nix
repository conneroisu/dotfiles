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
      url = "github:hyprwm/hyprland-qtutils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";

    agenix.url = "github:ryantm/agenix";

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
    agenix,
    vpn-confinement,
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
            system = systems.x86_64-linux;
            config.allowUnfree = true;
          };
          unstable-pkgs = import nixpkgs-unstable {
            system = systems.x86_64-linux;
            config.allowUnfree = true;
          };
          inherit
            self
            stylix
            zen-browser
            hyprwm-qtutils
            agenix
            vpn-confinement
            ;
        };
        modules = [
          nixos-hardware.nixosModules.dell-xps-15-9510
          stylix.nixosModules.stylix
          nix-ld.nixosModules.nix-ld
          agenix.nixosModules.default
          vpn-confinement.nixosModules.default
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
            config.allowUnfree = true;
          };
          unstable-pkgs = import nixpkgs-unstable {
            system = systems.aarch64-darwin;
            config.allowUnfree = true;
          };
          inherit self zen-browser agenix vpn-confinement;
          inherit
            (inputs)
            homebrew-core
            homebrew-cask
            homebrew-bundle
            ;
        };
        modules = [
          nix-homebrew.darwinModules.nix-homebrew
          agenix.darwinModules.agenix
          ./hosts/Shared
          ./hosts/aarch64-darwin
        ];
      };
    };
  };
}
