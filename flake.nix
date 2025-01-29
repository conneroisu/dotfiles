{
  description = "Conner Ohnesorge's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:conneroisu/zen-browser-flake?tag=v0.1.0";

    stylix.url = "github:danth/stylix";

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

    darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
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

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nufmt = {
      url = "github:nushell/nufmt";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    ashell = {
      url = "github:MalpenZibo/ashell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };
  nixConfig = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    extra-trusted-public-keys = "conneroisu.cachix.org-1:PgOlJ8/5i/XBz2HhKZIYBSxNiyzalr1B/63T74lRcU0=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = {self, ...} @ inputs: let
    inherit (inputs) snowfall-lib;
    lib = snowfall-lib.mkLib {
      inherit inputs;
      src = ./nix;

      snowfall = {
        namespace = "csnow";
        meta = {
          name = "csnow";
          title = "Conner Ohnesorge's Snowflake";
        };
      };
    };
    experiments = {
      nix.settings.experimental-features = ["nix-command" "flakes"];
    };
    homie = {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
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
          ./nix/modules/shared
          home-manager.nixosModules.home-manager
          stylix.nixosModules.stylix
          nix-ld.nixosModules.nix-ld
          disko.nixosModules.disko
          nur.modules.nixos.default
          {programs.nix-ld.dev.enable = true;}
          sops-nix.nixosModules.default
          experiments
          homie
        ];

        # Add modules to all Darwin systems.
        darwin = with inputs; [
          ./nix/modules/shared
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          sops-nix.darwinModules.default
          experiments
          homie
        ];
      };
      outputs-builder = channels: {
        formatter = channels.nixpkgs.alejandra;
      };
    };
}
