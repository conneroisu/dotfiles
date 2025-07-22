{
  description = "Rust + Python development environment with optional CUDA support";

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

        # CUDA support only available on Linux systems
        cudaSupport = pkgs.stdenv.isLinux;
        cudaPackages = pkgs.lib.optionals cudaSupport [
          pkgs.cudaPackages.cudatoolkit
        ];

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
            echo "🦀 Rust + 🐍 Python${pkgs.lib.optionalString cudaSupport " + CUDA"} development environment"
            echo "Available commands:"
            ${pkgs.lib.concatStringsSep "\n" (
              pkgs.lib.mapAttrsToList (name: script: ''echo "  ${name} - ${script.description}"'') scripts
            )}
            echo ""

            ${pkgs.lib.optionalString cudaSupport ''
            # Set environment variables for CUDA
            export CUDA_PATH=${pkgs.cudaPackages.cudatoolkit}
            ''}
          '';

          env = {
            RUST_BACKTRACE = "1";
            DEV = "1";
            LOCAL = "1";
          } // (pkgs.lib.optionalAttrs cudaSupport {
            CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
            LD_LIBRARY_PATH = "${pkgs.cudaPackages.cudatoolkit}/lib:${pkgs.stdenv.cc.cc.lib}/lib";
          });

          shell-packages =
            [
              # Nix development tools
              pkgs.alejandra
              pkgs.nixd
              pkgs.nil
              pkgs.statix
              pkgs.deadnix

              # Python tools
              pkgs.uv
              pkgs.ruff
              pkgs.mypy

              # Rust toolchain and tools
              rustToolchain
              pkgs.cargo-watch
              pkgs.cargo-edit

              # Build tools
              pkgs.pkg-config
              pkgs.protobuf
            ]
            ++ cudaPackages
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
