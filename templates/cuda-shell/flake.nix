{
  description = "Rust + Python development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
  }:
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux" "aarch64-darwin"] (
      system: let
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = ["rust-src" "clippy" "rustfmt"];
        };

        # Platform-specific packages
        linuxPackages = pkgs.lib.optionals pkgs.stdenv.isLinux [
          pkgs.libGL
          pkgs.mesa
          pkgs.xorg.libX11
          pkgs.xorg.libXrandr
          pkgs.xorg.libXinerama
          pkgs.xorg.libXcursor
          pkgs.xorg.libXi
        ];

        darwinPackages = pkgs.lib.optionals pkgs.stdenv.isDarwin [
          pkgs.libiconv
          pkgs.darwin.apple_sdk.frameworks.CoreFoundation
          pkgs.darwin.apple_sdk.frameworks.CoreServices
          pkgs.darwin.apple_sdk.frameworks.Foundation
          pkgs.darwin.apple_sdk.frameworks.Security
          pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
        ];


        rooted = exec:
          builtins.concatStringsSep "\n"
          [
            ''REPO_ROOT="$(git rev-parse --show-toplevel)"''
            exec
          ];

        scripts = {
          dx = {
            exec = rooted ''$EDITOR "$REPO_ROOT"/flake.nix'';
            description = "Edit flake.nix";
          };
          cx = {
            exec = rooted ''$EDITOR "$REPO_ROOT"/Cargo.toml'';
            description = "Edit Cargo.toml";
          };
          px = {
            exec = rooted ''$EDITOR "$REPO_ROOT"/pyproject.toml'';
            description = "Edit pyproject.toml";
          };
          clean = {
            exec = ''git clean -fdx'';
            description = "Clean project";
          };
          lint-python = {
            exec = rooted ''
              cd "$REPO_ROOT"
              ruff check .
              ruff format --check .
              mypy . || true
            '';
            deps = with pkgs; [ruff mypy];
            description = "Lint Python code";
          };
          lint-rust = {
            exec = rooted ''
              cd "$REPO_ROOT"
              cargo clippy -- -D warnings
              cargo fmt --check
            '';
            deps = [rustToolchain];
            description = "Lint Rust code";
          };
          lint = {
            exec = rooted ''
              lint-python
              lint-rust
              statix check "$REPO_ROOT"
              deadnix "$REPO_ROOT"/flake.nix
              nix flake check
            '';
            deps = with pkgs; [statix deadnix ruff mypy] ++ [rustToolchain];
            description = "Run all linting steps";
          };
          build-rust = {
            exec = rooted ''cd "$REPO_ROOT" && cargo build'';
            deps = [rustToolchain];
            description = "Build Rust service";
          };
          build-nix = {
            exec = rooted ''cd "$REPO_ROOT" && nix build'';
            deps = [];
            description = "Build with Nix";
          };
          run-rust = {
            exec = rooted ''cd "$REPO_ROOT" && cargo run'';
            deps = [rustToolchain];
            description = "Run Rust service";
          };
          format = {
            exec = rooted ''
              cd "$REPO_ROOT"
              cargo fmt
              ruff format .
              alejandra "$REPO_ROOT"/flake.nix
            '';
            deps = with pkgs; [alejandra ruff] ++ [rustToolchain];
            description = "Format all code";
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
                runtimeEnv = script.env or {};
              }
          )
          scripts;
      in {
        devShells = let
          shellHook = ''
            echo "🦀 Rust + 🐍 Python development environment"
            echo "Available commands:"
            ${pkgs.lib.concatStringsSep "\n" (
              pkgs.lib.mapAttrsToList (name: script: ''echo "  ${name} - ${script.description}"'') scripts
            )}
            echo ""
          '';

          env = {
            RUST_BACKTRACE = "1";
            DEV = "1";
            LOCAL = "1";
          } // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
            LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
          } // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
            DYLD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
          };

          corePackages = [
            # Nix development tools
            pkgs.alejandra
            pkgs.nixd
            pkgs.nil
            pkgs.statix
            pkgs.deadnix
          ];

          pythonPackages = [
            pkgs.uv
            pkgs.ruff
            pkgs.mypy
          ];

          rustPackages = [
            rustToolchain
            pkgs.cargo-watch
            pkgs.cargo-edit
          ];

          systemPackages = [
            pkgs.pkg-config
            pkgs.protobuf
            pkgs.openssl
            pkgs.opencv4
          ];

          shell-packages = corePackages
            ++ pythonPackages
            ++ rustPackages
            ++ systemPackages
            ++ linuxPackages
            ++ darwinPackages
            ++ builtins.attrValues scriptPackages;
        in {
          default = pkgs.mkShell {
            inherit shellHook env;
            packages = shell-packages;
          };
        };

        packages = {
          # Add custom packages here
        };
      }
    );
}
