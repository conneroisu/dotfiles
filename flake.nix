{
  description = "Modular configuration of Home Manager and NixOS with Denix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    zen-browser.url = "github:connerohnesorge/zen-browser-flake";
    proton-authenticator.url = "github:conneroisu/proton-authenticator-flake?ref=0494e1b70724861b4f8e2fb314b744e0591dfbb5";
    proton-authenticator.inputs.nixpkgs.follows = "nixpkgs";

    spectr.url = "github:connerohnesorge/spectr";
    spectr.inputs.nixpkgs.follows = "nixpkgs";

    conclaude.url = "github:connix-io/conclaude";
    conclaude.inputs.nixpkgs.follows = "nixpkgs";

    nix-ai-tools = {
      url = "github:numtide/nix-ai-tools";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    kiro-flake = {
      url = "github:connerohnesorge/kiro-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nordvpn.url = "github:connerohnesorge/nordvpn-flake/?ref=0d524b475205d8a69cd7e954580c49493ac6156a";
    nordvpn.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    flake-utils.url = "github:numtide/flake-utils";
    systems.url = "github:nix-systems/default";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    denix = {
      url = "github:yunfachi/denix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        nix-darwin.follows = "nix-darwin";
      };
    };

    hyprland.url = "github:hyprwm/hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "https://flakehub.com/f/danth/stylix/0.1.776";
    stylix.inputs = {
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
    };

    ghostty.url = "github:ghostty-org/ghostty/main";
    ghostty.inputs = {
      nixpkgs.follows = "nixpkgs";
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

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-auth.url = "github:numtide/nix-auth";
    nix-auth.inputs.nixpkgs.follows = "nixpkgs";

    nix-version-search = {
      url = "github:jeff-hykin/nix_version_search_cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
  };

  outputs = inputs @ {
    denix,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [];

      flake = let
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

        templates = {
          devshell = {
            description = "A devshell for developing with nix.";
            path = ./templates/devshell;
          };
          go-shell = {
            description = "A go shell for developing with nix.";
            path = ./templates/go-shell;
          };
          templ-shell = {
            description = "A go + templ shell for developing with nix.";
            path = ./templates/templ-shell;
          };
          rust-shell = {
            description = "A rust shell for developing with nix.";
            path = ./templates/rust-shell;
          };
          askama-shell = {
            description = "A rust web shell for developing with nix and askama.";
            path = ./templates/askama-shell;
          };
          typescript-shell = {
            description = "A TypeScript shell with modern tooling (ESLint, oxlint, Biome, LSPs).";
            path = ./templates/typescript-shell;
          };
          remix-shell = {
            description = "A Remix JS shell for developing with bun.";
            path = ./templates/remix-shell;
          };
          phoenix-shell = {
            description = "An Elixir Phoenix Framework shell for developing with nix.";
            path = ./templates/phoenix-shell;
          };
          laravel-shell = {
            description = "A Laravel shell for developing with nix.";
            path = ./templates/laravel-shell;
          };
          lua-shell = {
            description = "A lua shell for developing with nix.";
            path = ./templates/lua-shell;
          };
          ocaml-shell = {
            description = "An OCaml shell with modern tooling and best practices.";
            path = ./templates/ocaml-shell;
          };
          python-shell = {
            description = "A Python shell with modern tooling (basedpyright, ruff, black, pytest).";
            path = ./templates/python-shell;
          };
          cpp-shell = {
            description = "A C++ shell with modern tooling (GCC, Clang, CMake, static analysis).";
            path = ./templates/cpp-shell;
          };
          csharp-shell = {
            description = "A C# development shell with .NET 8 SDK and buildDotnetModule support.";
            path = ./templates/csharp-shell;
          };
          cuda-shell = {
            description = "A cuda shell for developing with nix.";
            path = ./templates/cuda-shell;
          };
          zig-shell = {
            description = "A zig shell for developing with nix.";
            path = ./templates/zig-shell;
          };
          starlight-shell = {
            description = "A astro starlight docs site shell/project for developing with nix.";
            path = ./templates/starlight-shell;
          };
          latex-shell = {
            description = "A LaTeX development shell with Overleaf-equivalent features.";
            path = ./templates/latex-shell;
          };
        };
      };

      perSystem = {
        # config,
        # self',
        # inputs',
        pkgs,
        # system,
        ...
      }: let
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
              find . -name "go.mod" -type f | while read -r modfile; do
                  DIR=$(dirname "$modfile")
                  echo "Linting: $DIR"
                  (cd "$DIR" && golangci-lint run ./...) || echo "Go linting completed with warnings"
              done
              nix flake check "$REPO_ROOT"
            '';
            deps = with pkgs; [git statix deadnix golangci-lint];
            description = "Run linting tools (statix, deadnix, nix flake check)";
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

        treefmtModule = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true; # Nix formatter
            rustfmt.enable = true; # Rust formatter
            black.enable = true; # Python formatter
          };
        };
      in {
        devShells.default = pkgs.mkShell {
          shellHook = ''
            export REPO_ROOT="$(git rev-parse --show-toplevel)"
            export CGO_CFLAGS="-O2"
          '';
          packages = with pkgs;
            [
              alejandra # Nix
              nixd
              gum # Terminal UI toolkit
              xmlstarlet
              xml2

              ruff # Python
              black
              isort
              basedpyright
              luajitPackages.luacheck
              biome
              oxlint

              pyrefly
              poppler
              sqlite
              go
              air
              golangci-lint
              gopls
              revive
              templ
              golines
              golangci-lint-langserver
              gomarkdoc
              gotests
              gotools
              reftools

              geesefs
              sops
            ]
            ++ builtins.attrValues scriptPackages;
        };

        formatter = inputs.treefmt-nix.lib.mkWrapper pkgs treefmtModule;
      };
    };
}
