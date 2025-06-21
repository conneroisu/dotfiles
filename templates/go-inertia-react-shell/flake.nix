{
  description = "A development shell for Go with Inertia.js and React";

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
  in {
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
            go mod init myapp
            go get github.com/romsar/gonertia/v2
            bun init -y
            bun add react react-dom @vitejs/plugin-react @inertiajs/react vite
            bun add -D @types/react @types/react-dom typescript
            bun2nix -o bun.nix
          '';
          description = "Initialize Go module and install dependencies";
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
        name = "go-inertia-react-dev";

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
          echo "Go + Inertia.js + React Development Shell"
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

      default = pkgs.buildGoModule {
        pname = "go-inertia-react-app";
        version = "0.1.0";
        src = ./.;
        vendorHash = null;
        doCheck = false;

        buildInputs = with pkgs; [go];

        # Frontend build disabled until dependencies are installed
        # preBuild = ''
        #   mkdir -p resources/build
        #   cp -r ${frontend}/dist/* resources/build/
        # '';

        meta = with pkgs.lib; {
          description = "Go + Inertia.js + React application";
          homepage = "https://github.com/conneroisu/go-inertia-react-shell";
          license = licenses.mit;
          maintainers = with maintainers; [];
        };
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
