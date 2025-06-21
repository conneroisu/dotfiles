{
  description = "A development shell for Go with Inertia.js and Vue";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    bun2nix.url = "github:baileyluTCD/bun2nix";
    bun2nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    nixpkgs,
    treefmt-nix,
    bun2nix,
    ...
  }: let
    supportedSystems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in rec {
    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
      };

      scripts = {
        dx = {
          exec = ''$EDITOR "$REPO_ROOT"/flake.nix'';
          description = "Edit flake.nix";
        };
        gx = {
          exec = ''$EDITOR "$REPO_ROOT"/go.mod'';
          description = "Edit go.mod";
        };
        px = {
          exec = ''$EDITOR "$REPO_ROOT"/package.json'';
          description = "Edit package.json";
        };
        vx = {
          exec = ''$EDITOR "$REPO_ROOT"/vite.config.js'';
          description = "Edit vite.config.js";
        };
        dev = {
          exec = ''
            # Start the Go server and Vite dev server concurrently
            (trap 'kill 0' EXIT; air & bun run dev)
          '';
          description = "Run Go server with air and Vite dev server";
        };
        build = {
          exec = ''
            bun run build && go build -o bin/server ./cmd/server
          '';
          description = "Build frontend assets and Go binary";
        };
        setup = {
          exec = ''
            echo "Installing dependencies..."
            bun install
            echo "Building frontend assets..."
            bun run build
            echo "Setup complete! Run 'dev' to start the development server."
          '';
          description = "Install dependencies and build frontend";
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
        name = "go-inertia-vue-dev";

        # Available packages on https://search.nixos.org/packages
        packages = with pkgs;
          [
            alejandra # Nix
            nixd
            statix
            deadnix

            go_1_24 # Go Tools
            air
            golangci-lint
            gopls
            (buildWithSpecificGo revive)
            (buildWithSpecificGo golines)
            (buildWithSpecificGo golangci-lint-langserver)
            (buildWithSpecificGo gomarkdoc)
            (buildWithSpecificGo gotests)
            (buildWithSpecificGo gotools)
            (buildWithSpecificGo reftools)
            pprof
            graphviz
            goreleaser
            cobra-cli

            nodejs # JavaScript Tools
            bun
            bun2nix.packages.${system}.default
            yarn
            nodePackages.pnpm
            nodePackages.prettier
            nodePackages.eslint
            nodePackages.typescript
            nodePackages.typescript-language-server
            playwright-driver
            chromium
          ]
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
          export REPO_ROOT=$(git rev-parse --show-toplevel)
          export PLAYWRIGHT_BROWSERS_PATH=${pkgs.chromium}
          export PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=${pkgs.chromium}/bin/chromium
          echo "Go + Inertia.js + Vue Development Shell"
          echo ""
          echo "Quick start:"
          echo "  setup  - Initialize project with dependencies"
          echo "  dev    - Run development servers"
          echo "  build  - Build for production"
          echo ""
          echo "Edit config files:"
          echo "  dx - Edit flake.nix"
          echo "  gx - Edit go.mod"
          echo "  px - Edit package.json"
          echo "  vx - Edit vite.config.js"
        '';
      };
    });

    packages = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      # Frontend package commented out until bun.nix is properly generated
      # frontend = pkgs.callPackage ./frontend.nix {
      #   inherit (bun2nix.lib.${system}) mkBunDerivation;
      # };

      # Development version that requires pre-built assets
      default = pkgs.buildGoModule {
        pname = "go-inertia-vue-app";
        version = "0.1.0";
        src = ./.;
        vendorHash = "sha256-PMd1wJ8aBIoYNVgItS7Q+L5IJXGeumHAfm6l12iu6R0=";
        doCheck = false;

        buildInputs = with pkgs; [go];

        postInstall = ''
          mkdir -p $out/share/go-inertia-vue-app
          
          # Copy resources
          cp -r resources $out/share/go-inertia-vue-app/
          
          # Copy pre-built assets if they exist
          if [ -d public ]; then
            cp -r public $out/share/go-inertia-vue-app/
          fi
          
          # Create wrapper script that changes to the app directory
          mv $out/bin/myapp $out/share/go-inertia-vue-app/
          cat > $out/bin/go-inertia-vue-app <<EOF
          #!/usr/bin/env bash
          cd $out/share/go-inertia-vue-app
          exec ./myapp
          EOF
          chmod +x $out/bin/go-inertia-vue-app
        '';

        meta = with pkgs.lib; {
          description = "Go + Inertia.js + Vue application";
          homepage = "https://github.com/conneroisu/go-inertia-vue-shell";
          license = licenses.mit;
          maintainers = with maintainers; [];
        };
      };
    });

    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${packages.${system}.default}/bin/go-inertia-vue-app";
      };
    });

    formatter = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtModule = {
        projectRootFile = "flake.nix";
        programs = {
          alejandra.enable = true; # Nix formatter
        };
      };
    in
      treefmt-nix.lib.mkWrapper pkgs treefmtModule);
  };
}
