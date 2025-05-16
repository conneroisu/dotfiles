{
  description = "Modular configuration of Home Manager and NixOS with Denix";

  inputs = {
    zen-browser.url = "github:conneroisu/zen-browser-flake?tag=v1.11.5b";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    ashell.url = "https://flakehub.com/f/conneroisu/ashell/0.1.527";
    ashell.inputs = {
      nixpkgs.follows = "nixpkgs";
    };

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

    zed.url = "github:zed-industries/zed/main";
    zed.inputs.nixpkgs.follows = "nixpkgs";

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
    blink.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
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
    mkConfigurations = isHomeManager:
      denix.lib.configurations {
        homeManagerUser = "connerohnesorge";
        inherit isHomeManager;

        paths = [./hosts ./modules ./rices];

        specialArgs = {
          inherit inputs;
        };
      };
  in {
    nixosConfigurations = mkConfigurations false;
    homeConfigurations = mkConfigurations true;

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
    };

    devShells = forAllSystems (system: let
      #
      pkgs = import nixpkgs {inherit system;};

      scripts = {
        dx = {
          exec = ''$EDITOR "$REPO_ROOT"/flake.nix'';
          description = "Edit the flake.nix";
          deps = [];
        };
        lint = {
          exec = ''
            REPO_ROOT="$(git rev-parse --show-toplevel)"
            golangci-lint run --fix
            statix check "$REPO_ROOT"/flake.nix
            deadnix "$REPO_ROOT"/flake.nix
          '';
          deps = with pkgs; [git statix deadnix];
          description = "Run golangci-lint";
        };
      };

      scriptPackages =
        pkgs.lib.mapAttrs
        (
          name: script:
            pkgs.writeShellApplication {
              inherit name;
              text = script.exec;
              runtimeInputs = script.deps or [];
            }
        )
        scripts;
    in {
      default = pkgs.mkShell {
        shellHook = ''
          export REPO_ROOT="$(git rev-parse --show-toplevel)"
          export CGO_CFLAGS="-O2"

          # Print available commands
          echo "Available commands:"
          ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: script: ''echo "  ${name} - ${script.description}"'') scripts)}

          echo "Git Status:"
          git status
        '';
        packages = with pkgs;
          [
            alejandra # Nix
            nixd
            ruff # Python
            black
            isort
            basedpyright
          ]
          ++ builtins.attrValues scriptPackages;
      };
    });
  };
}
