{
  description = "Conner Ohnesorge's NixOS Config";

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
    };

    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homebrew-core = {
      url = "github:Homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:Homebrew/homebrew-cask";
      flake = false;
    };

    homebrew-bundle = {
      url = "github:Homebrew/homebrew-bundle";
      flake = false;
    };

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ashell = {
      url = "github:MalpenZibo/ashell?rev=4a1c9e0c788e0e1c4aac9522d39a44cce7c24ef2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nh = {
      url = "github:viperML/nh/master?tag=v4.0.0-beta.8";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    snowfall-flake = {
      url = "github:snowfallorg/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser.url = "github:conneroisu/zen-browser-flake?tag=v1.10.4";

    stylix.url = "github:danth/stylix";

    ghostty.url = "github:ghostty-org/ghostty/main";

    sops-nix.url = "github:Mic92/sops-nix";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    systems.url = "github:nix-systems/default";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";

    hyprland.url = "github:hyprwm/hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    clan-core.url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
    nixpkgs.follows = "clan-core/nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    blink.url = "github:Saghen/blink.cmp";
    blink.inputs = {
      # TODO: follow fenix
      nixpkgs.follows = "nixpkgs";
      flake-parts.follows = "flake-parts";
    };
  };

  nixConfig = {
    extra-substituters = ''
      https://cache.nixos.org
      https://nix-community.cachix.org
      https://devenv.cachix.org
    '';
    extra-trusted-public-keys = ''
      cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
      nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
      devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=
    '';
    trusted-users = [
      "root"
      "@wheel"
      "connerohnesorge"
    ];
    extra-experimental-features = "nix-command flakes";
    max-jobs = 8;
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {};
      flake = let
        inherit (inputs) snowfall-lib;
        lib = snowfall-lib.mkLib {
          inherit inputs;
          src = ./.;

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
        homie = {
          home-manager.useGlobalPkgs = false;
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
              determinate.nixosModules.default
              ./modules/shared
              home-manager.nixosModules.home-manager
              stylix.nixosModules.stylix
              nix-ld.nixosModules.nix-ld
              disko.nixosModules.disko
              nur.modules.nixos.default
              {programs.nix-ld.dev.enable = true;}
              sops-nix.nixosModules.default
              nix-index-database.nixosModules.nix-index
              config
              homie
            ];

            # Add modules to all Darwin systems.
            darwin = with inputs; [
              {nix.nixPath = ["darwin=/Users/connerohnesorge/.nix-defexpr/darwin"];}
              ./modules/shared
              nix-homebrew.darwinModules.nix-homebrew
              home-manager.darwinModules.home-manager
              sops-nix.darwinModules.default
              nix-index-database.darwinModules.nix-index
              config
              homie
            ];
          };
          outputs-builder = channels: {
            formatter = channels.nixpkgs.alejandra;
          };
        };
    };
}
