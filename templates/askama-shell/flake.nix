{
  description = "Rust Web Shell Template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      overlays = [(import rust-overlay)];
      pkgs = import nixpkgs {
        inherit system overlays;
      };

      rustToolchain = pkgs.rust-bin.stable.latest.default.override {
        extensions = ["rust-src" "rust-analyzer"];
      };
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs;
          [
            rustToolchain
            cargo-watch
            cargo-edit

            # Node.js for TailwindCSS and TypeScript
            bun
            nodejs_20
            nodePackages.npm
            nodePackages.typescript
            nodePackages.tailwindcss

            # Database tools
            sqlite
            postgresql
            tailwindcss

            # Development tools
            just
            watchexec

            # System dependencies
            pkg-config
            openssl
            libiconv
          ]
          ++ lib.optionals stdenv.isDarwin [
            darwin.apple_sdk.frameworks.Security
            darwin.apple_sdk.frameworks.SystemConfiguration
          ];

        shellHook = ''
          echo "🦀 Rust Web Shell Development Environment"
          echo "📦 Rust version: $(rustc --version)"
          echo "📦 Node version: $(node --version)"
          echo ""
          echo "Available commands:"
          echo "  cargo run        - Run the development server"
          echo "  cargo watch -x run - Auto-reload on changes"
          echo "  just dev         - Development workflow"
          echo "  just build       - Build for production"
          echo ""
        '';

        RUST_LOG = "debug";
        DATABASE_URL = "sqlite:app.db";
      };
    });
}
