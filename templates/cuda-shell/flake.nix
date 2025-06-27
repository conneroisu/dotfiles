{
  description = "v1-llm development environment";

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

        # Prefer usage of uv
        # pythonEnv = pkgs.python311.withPackages (ps:
        #   with ps; [
        #     pip
        #     torch-bin
        #     torchvision-bin
        #     transformers
        #     datasets
        #     accelerate
        #     boto3
        #     onnxruntime
        #     numpy
        #     scipy
        #     matplotlib
        #     jupyter
        #     ipython
        #     black
        #     ruff
        #     mypy
        #   ]);

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
            deps = with pkgs; [statix deadnix] ++ [rustToolchain];
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
              ruff format "$REPO_ROOT"/train
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
            echo "🦀 Rust + 🐍 Python Cuda development environment"
            echo "Available commands:"
            ${pkgs.lib.concatStringsSep "\n" (
              pkgs.lib.mapAttrsToList (name: script: ''echo "  ${name} - ${script.description}"'') scripts
            )}
            echo ""

            # Set environment variables for CUDA
            export CUDA_PATH=${pkgs.cudatoolkit}
          '';

          env = {
            CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
            LD_LIBRARY_PATH = "${pkgs.cudaPackages.cudatoolkit}/lib:${pkgs.stdenv.cc.cc.lib}/lib";
            RUST_BACKTRACE = "1";
            DEV = "1";
            LOCAL = "1";
          };

          shell-packages =
            [
              # Nix tools
              pkgs.alejandra
              pkgs.nixd
              pkgs.nil
              pkgs.statix
              pkgs.deadnix
              pkgs.uv

              # Rust toolchain
              rustToolchain
              pkgs.cargo-watch
              pkgs.cargo-edit

              # Build tools
              pkgs.pkg-config
              pkgs.protobuf

              # CUDA support
              pkgs.cudatoolkit
            ]
            ++ builtins.attrValues scriptPackages;
        in {
          default = pkgs.mkShell {
            inherit shellHook env;
            packages = shell-packages;
          };
        };

        packages = let
          # Build the Rust package
          # llm-package = pkgs.rustPlatform.buildRustPackage {
          #   pname = "v1-llm";
          #   version = "0.1.0";
          #   src = ./.;
          #   cargoLock = {
          #     lockFile = ./Cargo.lock;
          #   };
          #
          #   buildInputs = with pkgs;
          #     [
          #       openssl
          #       pkg-config
          #     ]
          #     ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
          #       libiconv
          #       darwin.apple_sdk.frameworks.Security
          #       darwin.apple_sdk.frameworks.SystemConfiguration
          #     ];
          #
          #   nativeBuildInputs = with pkgs; [
          #     pkg-config
          #     protobuf
          #   ];
          # };
        in {
        };
      }
    );
}
