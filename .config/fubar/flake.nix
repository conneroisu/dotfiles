{
  description = "Fabric Bar Example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/24.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    fabric.url = "github:wholikeel/fabric-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      unstable,
      utils,
      fabric,
      ...
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        # Dependencies want from nixpkgs unstable as an overlay
        unstable-overlay = final: prev: { basedpyright = unstable.legacyPackages.${system}.basedpyright; };
        # Fabric overlay
        fabric-overlay = fabric.overlays.${system}.default;
        # Apply both overlays
        pkgs = (nixpkgs.legacyPackages.${system}.extend fabric-overlay).extend unstable-overlay;
      in
      {
        formatter = pkgs.nixfmt-rfc-style;
        devShells.default = pkgs.callPackage ./shell.nix { inherit pkgs; };
        packages.default = pkgs.callPackage ./derivation.nix { inherit (pkgs) lib python3Packages; };
        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/bar";
        };
      }
    );
}
