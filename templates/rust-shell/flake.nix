{
  description = "A development shell for rust";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    rust-overlay,
    treefmt-nix,
    ...
  }: let
    # Define systems
    systems = [
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    # Helper function to generate per-system attributes
    forAllSystems = f: nixpkgs.lib.genAttrs systems f;
  in {
    # Define devShells for all systems
    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [rust-overlay.overlays.default];
      };
    in {
      default = pkgs.mkShell {
        name = "dev";
        # Available packages on https://search.nixos.org/packages
        buildInputs = with pkgs; [
          alejandra # Nix
          nixd
          statix
          deadnix
          just
          rust-bin.stable.latest.default
        ];
        shellHook = ''
          echo "Welcome to the rust devshell!"
        '';
        env = {
          # use a folder per toolchain name to store rust's cache
          CARGO_HOME = "$HOME/.cargo";
          RUSTUP_HOME = "$HOME/.rustup";
        };
      };
    });

    formatter = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [rust-overlay.overlays.default];
      };
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
