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
      url = "github:nix-community/home-manager/release-24.11";
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
    agenix.url = "github:ryantm/agenix";
  };

  outputs = inputs @ {
    self,
    darwin,
    nix-ld,
    stylix,
    nixpkgs,
    home-manager,
    nix-homebrew,
    nixos-hardware,
    nixpkgs-unstable,
    ...
  }: let
    systems = {
      x86_64-linux = "x86_64-linux";
      x86_64-darwin = "x86_64-darwin";
      aarch64-linux = "aarch64-linux";
      aarch64-darwin = "aarch64-darwin";
    };
    x86_64-linux-pkgs = import nixpkgs {
      system = systems.x86_64-linux;
      config = {allowUnfree = true;};
    };
    x86_64-linux-unstable-pkgs = import nixpkgs-unstable {
      system = systems.x86_64-linux;
      config = {allowUnfree = true;};
    };
    aarch64-linux-pkgs = import nixpkgs {
      system = systems.aarch64-linux;
      config = {allowUnfree = true;};
    };
    aarch64-darwin-pkgs = import nixpkgs {
      system = systems.aarch64-darwin;
      config = {allowUnfree = true;};
    };
    aarch64-linux-unstable-pkgs = import nixpkgs-unstable {
      system = systems.aarch64-linux;
      config = {allowUnfree = true;};
    };
    aarch64-darwin-unstable-pkgs = import nixpkgs-unstable {
      system = systems.aarch64-darwin;
      config = {allowUnfree = true;};
    };
  in {
    nixosConfigurations = {
      # nix build .#nixosConfigurations.nixos -o nixos
      nixos = nixpkgs.lib.nixosSystem {
        system = systems.x86_64-linux;
        specialArgs = {
          inherit x86_64-linux-pkgs x86_64-linux-unstable-pkgs inputs stylix self;
        };
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/x86_64-nixos
          nixos-hardware.nixosModules.dell-xps-15-9510
          nix-ld.nixosModules.nix-ld
          {programs.nix-ld.dev.enable = true;}
          inputs.stylix.nixosModules.stylix
        ];
      };
      # nix build .#nixosConfigurations.iso-aarch64.config.system.build.isoImage
      iso-aarch64 = nixpkgs.lib.nixosSystem {
        system = systems.aarch64-linux;
        specialArgs = {
          system = systems.aarch64-linux;
          inherit inputs stylix self;
          pkgs = aarch64-linux-pkgs;
          unstable-pkgs = aarch64-linux-unstable-pkgs;
        };
        modules = [
          ./hosts/iso-aarch64
          home-manager.nixosModules.home-manager
        ];
      };
    };

    darwinConfigurations = {
      # nix build .#darwinConfigurations.Conners-MacBook-Air -o Conners-MacBook-Air
      # darwin-rebuild switch --flake .#darwinConfigurations.Conners-MacBook-Air
      "Conners-MacBook-Air" = darwin.lib.darwinSystem {
        system = systems.aarch64-darwin;
        specialArgs = {
          inherit inputs self;
          pkgs = aarch64-darwin-pkgs;
          unstable-pkgs = aarch64-darwin-unstable-pkgs;
        };
        modules = [
          home-manager.darwinModules.home-manager
          ./hosts/aarch64-darwin
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.connerohnesorge = import ./home.nix;
              extraSpecialArgs = {
                inherit inputs self;
                pkgs = aarch64-darwin-pkgs;
                unstable-pkgs = aarch64-darwin-unstable-pkgs;
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
