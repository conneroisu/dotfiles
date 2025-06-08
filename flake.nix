{
  description = "Modular configuration of Home Manager and NixOS with Denix";

  inputs = {
    zen-browser.url = "github:conneroisu/zen-browser-flake?tag=v1.11.5b";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    ashell.url = "https://flakehub.com/f/conneroisu/ashell/0.1.538";
    ashell.inputs = {
      nixpkgs.follows = "nixpkgs";
    };
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    flake-utils.url = "github:numtide/flake-utils";
    systems.url = "github:nix-systems/default";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    denix = {
      url = "github:yunfachi/denix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    hyprland.url = "github:hyprwm/hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "https://flakehub.com/f/danth/stylix/0.1.776";
    stylix.inputs = {
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
      home-manager.follows = "home-manager";
    };

    ghostty.url = "github:ghostty-org/ghostty/main";
    ghostty.inputs = {
      flake-utils.follows = "flake-utils";
    };

    blink.url = "github:Saghen/blink.cmp";
    blink.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    denix,
    nixpkgs,
    ...
  } @ inputs: let
    supportedSystems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    mkConfigurations = moduleSystem:
      denix.lib.configurations {
        homeManagerUser = "connerohnesorge";
        inherit moduleSystem;

        paths = [./hosts ./modules ./rices];

        specialArgs = {
          inherit inputs;
        };
      };
  in {
    nixosConfigurations = mkConfigurations "nixos";
    homeConfigurations = mkConfigurations "home";
    darwinConfigurations = mkConfigurations "darwin";

    formatter = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtModule = {
        projectRootFile = "flake.nix";
        programs = {
          alejandra.enable = true; # Nix formatter
          rustfmt.enable = true; # Rust formatter
          black.enable = true; # Python formatter
        };
      };
    in
      inputs.treefmt-nix.lib.mkWrapper pkgs treefmtModule);

    templates = {
      devshell = {
        description = "A devshell for developing with nix";
        path = ./templates/devshell;
      };
      go-shell = {
        description = "A go shell for developing with nix";
        path = ./templates/go-shell;
      };
      rust-shell = {
        description = "A rust shell for developing with nix";
        path = ./templates/rust-shell;
      };
      remix-js-shell = {
        description = "A Remix JS shell for developing with bun";
        path = ./templates/remix-js-shell;
      };
      elixir-phoenix-shell = {
        description = "An Elixir Phoenix Framework shell for developing with nix";
        path = ./templates/elixir-phoenix-shell;
      };
      laravel-shell = {
        description = "A Laravel shell for developing with nix";
        path = ./templates/laravel-shell;
      };
    };
  };
}
