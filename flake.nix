{
  description = "Conner Ohnesorge's dotfiles";

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    determinate.inputs = {
      nixpkgs.follows = "nixpkgs";
      determinate-nixd-aarch64-darwin.follows = "";
      determinate-nixd-x86_64-darwin.follows = "";
    };
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    systems.url = "github:nix-systems/default-linux";

    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/0.1.5";

    hyprland.url = "github:hyprwm/hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "https://flakehub.com/f/hercules-ci/flake-parts/0.1.372";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    flake-utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    flake-utils.inputs.systems.follows = "systems";

    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";

    snowfall-lib.url = "https://flakehub.com/f/snowfallorg/lib/3.0.3";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "https://flakehub.com/f/nix-community/home-manager/0.2411.*";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    ashell.url = "https://flakehub.com/f/conneroisu/ashell/0.1.481";
    ashell.inputs = {
      nixpkgs.follows = "nixpkgs";
      rust-overlay.follows = "rust-overlay";
    };

    zed.url = "github:zed-industries/zed/main";
    zed.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "https://flakehub.com/f/oxalica/rust-overlay/0.1.1771";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:conneroisu/zen-browser-flake?tag=v1.11.5b";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "https://flakehub.com/f/danth/stylix/0.1.776";
    stylix.inputs = {
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
      home-manager.follows = "home-manager";
      flake-utils.follows = "flake-utils";
    };

    ghostty.url = "github:ghostty-org/ghostty/main";
    ghostty.inputs = {
      nixpkgs-unstable.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
    };

    blink.url = "github:Saghen/blink.cmp";
    blink.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-parts.follows = "flake-parts";
    };

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    codex.url = "github:conneroisu/codex";
    codex.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
    };
  };

  outputs = {
    flake-parts,
    snowfall-lib,
    flake-schemas,
    ...
  } @ inputs: let
    stateVersion = "24.11";
    helper = import ./home-manager/utils {inherit inputs stateVersion;};
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = _: {};
      flake = let
        lib = snowfall-lib.mkLib {
          inherit inputs;
          src = builtins.path {
            path = ./nix/.;
            name = "source";
          };
          snowfall = {
            namespace = "csnow";
            meta = {
              name = "csnow";
              title = "Conner Ohnesorge's Snowflake";
            };
          };
        };

        config = {
          nix.settings = {
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            trusted-users = [
              "root"
              "connerohnesorge"
              "@wheel"
            ];
            allowed-users = [
              "root"
              "connerohnesorge"
              "@wheel"
            ];
          };
        };
      in
        lib.mkFlake {
          channels-config = {
            allowUnfree = true;
          };
          systems.modules = {
            nixos = with inputs; [
              determinate.nixosModules.default
              ./nix/modules/shared
              home-manager.nixosModules.home-manager
              stylix.nixosModules.stylix
              config
            ];
          };
          outputs-builder = channels: {
            formatter = channels.nixpkgs.alejandra;
          };

          templates = {
            devshell.description = "A devshell for developing with nix";
            go-shell.description = "A go shell for developing with nix";
            rust-shell.description = "A rust shell for developing with nix";
          };
        }
        // {
          homeConfigurations = {
            "connerohnesorge@xps-nixos" = helper.mkHome {
              username = "connerohnesorge";
              hostname = "xps-nixos";
              platform = "x86_64-linux";
            };
          };
        };
    }
    // {inherit (flake-schemas) schemas;};
}
