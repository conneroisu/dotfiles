{
  description = "Conner Ohnesorge's Nix Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:conneroisu/zen-browser-flake";
    stylix.url = "github:danth/stylix";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nix-ld,
      nixos-hardware,
      stylix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
      unstable-pkgs = import nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
      inherit (self) inputs;
      inherit (pkgs) dbus;
    in
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              system
              pkgs
              unstable-pkgs
              inputs
              stylix
              ;
          };
          modules = [
            nixos-hardware.nixosModules.dell-xps-15-9510
            ./configuration.nix
            nix-ld.nixosModules.nix-ld
            { programs.nix-ld.dev.enable = true; }
            inputs.stylix.nixosModules.stylix
          ];
        };
      };
      darwinConfigurations."Conners-MacBook-Air" = inputs.nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # home-manager.users.connerohnesorge = import ./home.nix;
          }
          inputs.nix-homebrew.darwinModules.nix-homebrew
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
          ./hosts/darwin
        ];
      };
      stdenv.mkDerivation = {
        inherit dbus;
        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = with pkgs; [
          dbus
          webkitgtk
          openssl
        ];
      };
    };
}
