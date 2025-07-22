{
  description = "Modular configuration of Home Manager and NixOS with Denix";

  inputs = {
    zen-browser.url = "github:conneroisu/zen-browser-flake?tag=v1.14.4b";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    ashell.url = "github:MalpenZibo/ashell";
    ashell.inputs = {
      nixpkgs.follows = "nixpkgs";
    };
    nordvpn.url = "github:conneroisu/nordvpn-flake/?ref=0d524b475205d8a69cd7e954580c49493ac6156a";
    # nordvpn.url = "path:./nordvpn-flake";
    # parcl.url = "github:conneroisu/parcl";
    # parcl.inputs.nixpkgs.follows = "nixpkgs";
    claude-desktop.url = "github:k3d3/claude-desktop-linux-flake";
    claude-desktop.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
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
      inputs.nix-darwin.follows = "nix-darwin";
    };

    hyprland.url = "github:hyprwm/hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";

    nix-tree-rs.url = "github:Mic92/nix-tree-rs";
    nix-tree-rs.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "https://flakehub.com/f/danth/stylix/0.1.776";
    stylix.inputs = {
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
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

    nix-auth.url = "github:numtide/nix-auth";
    nix-auth.inputs.nixpkgs.follows = "nixpkgs";
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

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      scripts = {
        dx = {
          exec = ''$EDITOR "$REPO_ROOT"/flake.nix'';
          description = "Edit the flake.nix";
          deps = [];
        };
        lint = {
          exec = ''
            REPO_ROOT="$(git rev-parse --show-toplevel)"
            statix check "$REPO_ROOT"/flake.nix
            deadnix "$REPO_ROOT"/flake.nix
            nix flake check "$REPO_ROOT"
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

      buildWithSpecificGo = pkg: pkg.override {buildGoModule = pkgs.buildGo124Module;};
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
            luajitPackages.luacheck

            go_1_24 # Go
            air
            golangci-lint
            gopls
            (buildWithSpecificGo revive)
            (buildWithSpecificGo templ)
            (buildWithSpecificGo golines)
            (buildWithSpecificGo golangci-lint-langserver)
            (buildWithSpecificGo gomarkdoc)
            (buildWithSpecificGo gotests)
            (buildWithSpecificGo gotools)
            (buildWithSpecificGo reftools)
            pprof
            graphviz

            geesefs
            sops
          ]
          ++ builtins.attrValues scriptPackages;
      };
    });

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
      phoenix-shell = {
        description = "An Elixir Phoenix Framework shell for developing with nix";
        path = ./templates/phoenix-shell;
      };
      laravel-shell = {
        description = "A Laravel shell for developing with nix";
        path = ./templates/laravel-shell;
      };
      cuda-shell = {
        description = "A cuda shell for developing with nix";
        path = ./templates/cuda-shell;
      };
      zig-shell = {
        description = "A zig shell for developing with nix";
        path = ./templates/zig-shell;
      };
      rust-web-shell = {
        description = "A rust web shell for developing with nix";
        path = ./templates/rust-web-shell;
      };
    };
  };
}
