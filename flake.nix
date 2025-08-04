/**
# Main Flake Configuration - Denix-based Dotfiles

## Description
Sophisticated NixOS/Home Manager dotfiles repository using the Denix framework for
modular configuration management. Provides unified, cross-platform configuration
for NixOS, macOS (via nix-darwin), and standalone Home Manager setups.

## Platform Support
- ✅ NixOS (Linux) - Full system and user configuration
- ✅ macOS - Via nix-darwin with Home Manager integration
- ✅ Home Manager - Standalone user environment management
- ✅ Multi-architecture: x86_64, aarch64 (Apple Silicon, ARM)

## What This Provides
- **Modular Configuration**: Feature-based modules for desktop environments, development tools
- **Multi-Host Support**: Desktop, laptop, server configurations with host-specific features
- **Theme Management**: Stylix-based theming with Base16 color schemes
- **Development Environment**: Rich devShell with custom scripts and tools
- **Custom Programs**: Self-contained applications (dx, cmbd, convert_img, etc.)
- **Templates**: Ready-to-use development environments for various languages/frameworks

## Core Components
- **Denix Framework**: Type-safe, composable module system with auto-discovery
- **Feature System**: Granular capability enablement (audio, bluetooth, nvidia, etc.)
- **Host Types**: Desktop/laptop/server classifications with appropriate defaults
- **Rice System**: Consistent theming across all applications and environments

## Usage
```bash
# macOS rebuild
darwin-rebuild switch --flake .

# NixOS rebuild
sudo nixos-rebuild switch --flake .

# Home Manager only
home-manager switch --flake .
```

## Development
```bash
nix develop        # Enter development shell
nix develop -c dx  # Edit this flake
nix develop -c lint # Run quality checks
```
*/
{
  description = "Modular configuration of Home Manager and NixOS with Denix";

  inputs = {
    zen-browser.url = "github:conneroisu/zen-browser-flake?tag=v1.14.9b";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    ashell.url = "github:MalpenZibo/ashell?ref=1b57fbcba87f48ca1075dca48021ec55586caeea";
    ashell.inputs = {
      nixpkgs.follows = "nixpkgs";
    };
    nordvpn.url = "github:conneroisu/nordvpn-flake/?ref=0d524b475205d8a69cd7e954580c49493ac6156a";
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

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-auth.url = "github:numtide/nix-auth";
    nix-auth.inputs.nixpkgs.follows = "nixpkgs";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    locker = {
      url = "github:tgirlcloud/locker";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

          # Welcome header with gradient effect
          ${pkgs.gum}/bin/gum style \
            --foreground 212 --background 235 \
            --border thick --border-foreground 212 \
            --align center --width 60 --margin "1 0" --padding "1 2" \
            --bold "🚀 Dotfiles Development Environment"

          # Available commands section
          commands_header=$(${pkgs.gum}/bin/gum style \
            --foreground 99 --bold --underline "📋 Available Commands:")

          commands_content=""
          ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: script: ''commands_content="$commands_content$(${pkgs.gum}/bin/gum style --foreground 51 "▶ ${name}") $(${pkgs.gum}/bin/gum style --foreground 246 "${script.description}")\n"'') scripts)}

          commands_box=$(printf "$commands_content" | ${pkgs.gum}/bin/gum style \
            --border rounded --border-foreground 99 \
            --padding "0 2" --margin "0 2")

          ${pkgs.gum}/bin/gum join --vertical "$commands_header" "$commands_box"

          # Repository status section with enhanced visuals
          repo_header=$(${pkgs.gum}/bin/gum style \
            --foreground 212 --bold --underline "📊 Repository Status:")

          # Get repository info
          branch=$(git branch --show-current 2>/dev/null || echo "unknown")
          commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
          last_commit=$(git log -1 --format="%h - %s" 2>/dev/null || echo "No commits")

          # Branch info with icon
          branch_info=$(${pkgs.gum}/bin/gum style \
            --foreground 51 --bold "🌿 Branch: $branch")

          # Commit info
          commit_info=$(${pkgs.gum}/bin/gum style \
            --foreground 99 "📝 Commits: $commit_count")

          # Last commit info (truncated for readability)
          last_commit_short="''${last_commit:0:60}$([ ''${#last_commit} -gt 60 ] && echo "...")"
          last_commit_info=$(${pkgs.gum}/bin/gum style \
            --foreground 246 "🕐 Latest: $last_commit_short")

          # Check if there are any changes and create status display
          if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            change_count=$(git status --porcelain | wc -l | tr -d ' ')
            status_header=$(${pkgs.gum}/bin/gum style \
              --foreground 214 --bold "⚠️  $change_count file(s) changed:")

            # Create a table of changes using gum format
            changes_table=""
            while IFS= read -r line; do
              if [ -n "$line" ]; then
                status="''${line:0:2}"
                file="''${line:3}"
                case "$status" in
                  "M "|" M"|"MM")
                    changes_table="$changes_table$(${pkgs.gum}/bin/gum style --foreground 214 "│ 📝 Modified  │ $file")\n" ;;
                  "A "|" A")
                    changes_table="$changes_table$(${pkgs.gum}/bin/gum style --foreground 46 "│ ➕ Added     │ $file")\n" ;;
                  "D "|" D")
                    changes_table="$changes_table$(${pkgs.gum}/bin/gum style --foreground 196 "│ 🗑️  Deleted   │ $file")\n" ;;
                  "R "|" R")
                    changes_table="$changes_table$(${pkgs.gum}/bin/gum style --foreground 51 "│ 📁 Renamed   │ $file")\n" ;;
                  "??")
                    changes_table="$changes_table$(${pkgs.gum}/bin/gum style --foreground 99 "│ ❓ Untracked │ $file")\n" ;;
                  *)
                    changes_table="$changes_table$(${pkgs.gum}/bin/gum style --foreground 246 "│ 📄 $status      │ $file")\n" ;;
                esac
              fi
            done < <(git status --porcelain)

            # Format the changes table
            table_header=$(${pkgs.gum}/bin/gum style --foreground 246 --bold "┌─────────────┬────────────────────────────────────────┐")
            table_separator=$(${pkgs.gum}/bin/gum style --foreground 246 "└─────────────┴────────────────────────────────────────┘")

            changes_display=$(printf "$changes_table" | ${pkgs.gum}/bin/gum style \
              --border rounded --border-foreground 214 --padding "0 1")

            status_info="$status_header\n$changes_display"
          else
            status_info=$(${pkgs.gum}/bin/gum style \
              --foreground 46 --bold --border rounded --border-foreground 46 \
              --padding "1 2" --align center "✅ Repository is clean")
          fi

          # Combine all repository info
          repo_info=$(${pkgs.gum}/bin/gum join --vertical \
            "$branch_info" "$commit_info" "$last_commit_info")

          repo_box=$(echo "$repo_info" | ${pkgs.gum}/bin/gum style \
            --border rounded --border-foreground 212 \
            --padding "0 2" --margin "0 2")

          ${pkgs.gum}/bin/gum join --vertical "$repo_header" "$repo_box"

          # Display status info
          printf "$status_info\n"

          # Add a helpful tip
          tip=$(${pkgs.gum}/bin/gum style \
            --foreground 99 --italic \
            "💡 Tip: Use 'dx' to edit flake.nix, 'lint' to check code quality")

          ${pkgs.gum}/bin/gum style \
            --border rounded --border-foreground 99 \
            --padding "1 2" --margin "1 0" --align center \
            "$tip"
        '';
        packages = with pkgs;
          [
            alejandra # Nix
            nixd
            gum # Terminal UI toolkit

            ruff # Python
            black
            isort
            basedpyright
            luajitPackages.luacheck
            biome
            oxlint

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
      templ-shell = {
        description = "A go + templ shell for developing with nix";
        path = ./templates/templ-shell;
      };
      rust-shell = {
        description = "A rust shell for developing with nix";
        path = ./templates/rust-shell;
      };
      rust-web-shell = {
        description = "A rust web shell for developing with nix";
        path = ./templates/rust-web-shell;
      };
      typescript-shell = {
        description = "A TypeScript shell with modern tooling (ESLint, oxlint, Biome, LSPs)";
        path = ./templates/typescript-shell;
      };
      remix-shell = {
        description = "A Remix JS shell for developing with bun";
        path = ./templates/remix-shell;
      };
      tanstack-shell = {
        description = "A tanstack shell for developing with nix";
        path = ./templates/tanstack-shell;
      };
      phoenix-shell = {
        description = "An Elixir Phoenix Framework shell for developing with nix";
        path = ./templates/phoenix-shell;
      };
      laravel-shell = {
        description = "A Laravel shell for developing with nix";
        path = ./templates/laravel-shell;
      };
      lua-shell = {
        description = "A lua shell for developing with nix";
        path = ./templates/lua-shell;
      };
      ocaml-shell = {
        description = "An OCaml shell with modern tooling and best practices";
        path = ./templates/ocaml-shell;
      };
      python-shell = {
        description = "A Python shell with modern tooling (basedpyright, ruff, black, pytest)";
        path = ./templates/python-shell;
      };
      cpp-shell = {
        description = "A C++ shell with modern tooling (GCC, Clang, CMake, static analysis)";
        path = ./templates/cpp-shell;
      };
      cuda-shell = {
        description = "A cuda shell for developing with nix";
        path = ./templates/cuda-shell;
      };
      zig-shell = {
        description = "A zig shell for developing with nix";
        path = ./templates/zig-shell;
      };
    };
  };
}
