{
  description = "A development shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs @ {flake-parts, ...}:
  # https://flake.parts/
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem = {pkgs, ...}: {
        devShells.default = pkgs.mkShell {
          name = "dev";

          # Available packages on https://search.nixos.org/packages
          buildInputs = with pkgs; [
            just
          ];

          shellHook = ''
            echo "Welcome to the devshell!"
          '';
        };

        formatter = let
          treefmtModule = {
            projectRootFile = "flake.nix";
            programs = {
              alejandra.enable = true; # Nix formatter
            };
          };
        in
          inputs.treefmt-nix.lib.mkWrapper pkgs treefmtModule;
      };
    };
}
