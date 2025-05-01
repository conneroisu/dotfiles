{
  description = "Conner Ohnesorge's NixOS Config";

  inputs = {
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/0.1.5.tar.gz";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    hyprland.url = "https://flakehub.com/f/hyprwm/Hyprland/0.48.1";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    flake-parts.url = "https://flakehub.com/f/hercules-ci/flake-parts/0.1.372";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    flake-utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    flake-utils.inputs.systems.follows = "systems";

    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib = {
      url = "https://flakehub.com/f/snowfallorg/lib/3.0.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.2411.*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

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
      url = "https://flakehub.com/f/snowfallorg/flake/1.4.1.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "https://flakehub.com/f/oxalica/rust-overlay/0.1.1771.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser.url = "github:conneroisu/zen-browser-flake?tag=v1.10.4";

    stylix.url = "https://flakehub.com/f/danth/stylix/0.1.776";

    ghostty.url = "github:ghostty-org/ghostty/main";

    sops-nix.url = "https://flakehub.com/f/Mic92/sops-nix/0.1.887";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    systems.url = "github:nix-systems/default";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";

    fenix.url = "https://flakehub.com/f/nix-community/fenix/0.1.2184";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    blink.url = "github:Saghen/blink.cmp";
    blink.inputs = {
      fenix.follows = "fenix";
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
    # max-jobs = 8;
  };

  outputs = inputs @ {
    flake-parts,
    self,
    flake-schemas,
    home-manager,
    ...
  }: let
    inherit (self) outputs;
    stateVersion = "24.11";
    helper = import ./home-manager/utils {inherit inputs outputs stateVersion;};
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
              nur.modules.nixos.default
              {programs.nix-ld.dev.enable = true;}
              sops-nix.nixosModules.default
              config
            ];

            # Add modules to all Darwin systems.
            darwin = with inputs; [
              ./modules/shared
              nix-homebrew.darwinModules.nix-homebrew
              home-manager.darwinModules.home-manager
              sops-nix.darwinModules.default
              config
            ];
          };
          outputs-builder = channels: {
            formatter = channels.nixpkgs.alejandra;
          };
        }
        // {
          homeConfigurations = {
            "connerohnesorge@Conners-MacBook-Air.local" = helper.mkHome {
              username = "connerohnesorge";
              hostname = "Conners-MacBook-Air.local";
              platform = "aarch64-darwin";
            };
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
