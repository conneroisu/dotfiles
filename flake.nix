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
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:conneroisu/zen-browser-flake/master";
    };
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
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    zen-browser,
    darwin,
    nix-ld,
    stylix,
    home-manager,
    nix-homebrew,
    nixos-hardware,
    homebrew-core,
    homebrew-cask,
    homebrew-bundle,
    nixos-generators,
    ...
  } @ inputs: let
    systems = {
      x86_64-linux = "x86_64-linux";
      x86_64-darwin = "x86_64-darwin";
      aarch64-linux = "aarch64-linux";
      aarch64-darwin = "aarch64-darwin";
    };
  in {
    nixosConfigurations = {
      # nix build .#nixosConfigurations.nixosXPS -o nixosXPS
      nixosXPS = nixpkgs.lib.nixosSystem {
        system = systems.x86_64-linux;
        specialArgs = {
          inherit
            self
            stylix
            home-manager
            zen-browser
            ;
          pkgs = import nixpkgs {
            system = systems.x86_64-linux;
            config = {allowUnfree = true;};
          };
          unstable-pkgs = import nixpkgs-unstable {
            system = systems.x86_64-linux;
            config = {allowUnfree = true;};
          };
        };
        modules = [
          home-manager.nixosModules.home-manager
          nixos-hardware.nixosModules.dell-xps-15-9510
          stylix.nixosModules.stylix
          nix-ld.nixosModules.nix-ld
          {programs.nix-ld.dev.enable = true;}
          ./hosts/x86_64-nixos
        ];
      };
      # nix build .#nixosVM
      nixosVM = nixos-generators.nixosGenerate {
        system = systems.aarch64-linux;
        vbox = {
          specialArgs = {
            inherit
              self
              stylix
              home-manager
              zen-browser
              ;
            pkgs = import nixpkgs {
              system = systems.aarch64-linux;
              config = {allowUnfree = true;};
            };
            unstable-pkgs = import nixpkgs-unstable {
              system = systems.aarch64-linux;
              config = {allowUnfree = true;};
            };
          };
          modules = [
            home-manager.nixosModules.home-manager
            stylix.nixosModules.stylix
            nix-ld.nixosModules.nix-ld
            {programs.nix-ld.dev.enable = true;}
            ./hosts/x86_64-nixos
          ];
        };
        format = "virtualbox";
      };
    };

    darwinConfigurations = {
      # nix build .#darwinConfigurations.Conners-MacBook-Air -o Conners-MacBook-Air
      # darwin-rebuild switch --flake .#darwinConfigurations.Conners-MacBook-Air
      "Conners-MacBook-Air" = darwin.lib.darwinSystem {
        system = systems.aarch64-darwin;
        specialArgs = {
          inherit
            self
            homebrew-core
            homebrew-cask
            homebrew-bundle
            zen-browser
            ;
          pkgs = import nixpkgs {
            system = systems.aarch64-darwin;
            config = {allowUnfree = true;};
          };
          unstable-pkgs = import nixpkgs-unstable {
            system = systems.aarch64-darwin;
            config = {allowUnfree = true;};
          };
        };
        modules = [
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
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
  };
}
