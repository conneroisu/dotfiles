{
  description = "Conner Ohnesorge's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    devenv.url = "github:cachix/devenv";
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";

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

    darwin.url = "github:LnL7/nix-darwin/master";
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

    ashell = {
      url = "github:MalpenZibo/ashell?rev=96103fa1b3e936b4bff5e624eca023ddaf9c106f";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    nh = {
      url = "github:viperML/nh/master?tag=v4.0.0-beta.8";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = inputs @ {
    flake-parts,
    devenv-root,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = ["x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        devenv.shells.default = {
          devenv.root = let
            devenvRootFileContent = builtins.readFile devenv-root.outPath;
          in
            pkgs.lib.mkIf (devenvRootFileContent != "") devenvRootFileContent;

          name = "conneroh.com";

          cachix.enable = true;

          packages = with pkgs;
            [
              # Nix
              alejandra
              nixd

              # Terminal Utilities
              gum
              watchexec
              doppler
            ]
            ++ (pkgs.lib.optionals pkgs.stdenv.isLinux (with pkgs; [
                ]))
            ++ (pkgs.lib.optionals pkgs.stdenv.isDarwin (with pkgs; [
                ]));

          enterShell =
            ''

              export REPO_ROOT=$(git rev-parse --show-toplevel)
              export LD_LIBRARY_PATH=${
                pkgs.lib.makeLibraryPath (
                  (with pkgs; [
                    ])
                  ++ (pkgs.lib.optionals pkgs.stdenv.isLinux (
                    with pkgs; [
                    ]
                  ))
                  ++ (pkgs.lib.optionals pkgs.stdenv.isDarwin (
                    with pkgs; [
                    ]
                  ))
                )
              }:$LD_LIBRARY_PATH

            ''
            + pkgs.lib.optionalString pkgs.stdenv.isLinux ''
            ''
            + pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
            '';

          git-hooks = {
            hooks = {
              alejandra.enable = true;
            };
          };

          scripts = {
            status.exec = ''git status'';
          };

          languages = {
            nix = {
              enable = true;
            };
          };
        };
      };
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
              ./modules/shared
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
              ./modules/shared
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
    };
}
