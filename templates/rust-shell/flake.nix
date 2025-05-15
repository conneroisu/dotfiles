{
  description = "A development shell for rust";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {flake-parts, ...}:
  # https://flake.parts/
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem = {
        pkgs,
        inputs',
        ...
      }: let
        fenix = inputs'.fenix.packages;
        rustChannel = "stable";
      in {
        devShells.default = pkgs.mkShell {
          name = "dev";

          # Available packages on https://search.nixos.org/packages
          buildInputs = with pkgs; [
            alejandra # Nix
            nixd
            statix
            deadnix

            just
            (fenix.combine [
              fenix.${rustChannel}.toolchain

              # https://doc.rust-lang.org/rustc/platform-support.html
              # For more targets add:
              # fenix.targets.aarch64-linux-android."${rustChannel}".rust-std
              # fenix.targets.x86_64-linux-android."${rustChannel}".rust-std
            ])
          ];

          shellHook = ''
            echo "Welcome to the rust devshell!"
          '';

          # use a folder per toolchain name to store rust's cache
          CARGO_HOME = "$HOME/${fenix.${rustChannel}.toolchain.name}/.cargo";
          RUSTUP_HOME = "$HOME/${fenix.${rustChannel}.toolchain.name}/.rustup";
        };
      };
    };
}
