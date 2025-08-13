{
  description = "A TanStack (React) development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    treefmt-nix,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [];
      };
    in {
      devShells.default = pkgs.mkShell {
        name = "tanstack-shell";
        packages = with pkgs; [
          alejandra
          nixd

          nodejs
          bun
          typescript-language-server
          vscode-langservers-extracted
          biome
          oxlint
          tailwindcss-language-server
          yaml-language-server
        ];
      };

      formatter = treefmt-nix.lib.mkWrapper pkgs {
        projectRootFile = "flake.nix";
        programs = {
          alejandra.enable = true;
          prettier.enable = true;
        };
      };
    });
}
