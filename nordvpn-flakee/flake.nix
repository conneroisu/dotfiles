{
  description = "NordVPN package and NixOS module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ]
    (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        
        nordvpn = pkgs.callPackage ./nordvpn.nix {};
      in
      {
        packages = {
          default = nordvpn;
          inherit nordvpn;
        };

        apps = {
          default = {
            type = "app";
            program = "${nordvpn}/bin/nordvpn";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nixd
            nil
            alejandra
            statix
            deadnix
          ];
          shellHook = ''
            echo "NordVPN flake development environment"
            echo "Available commands:"
            echo "  nix build .#nordvpn - Build the package"
            echo "  nix flake check - Check flake validity"
            echo "  nixfmt-rfc-style . - Format nix files"
            echo "  statix check . - Check for common nix issues"
            echo "  deadnix . - Find dead code in nix files"
          '';
        };
      }
    ) // {
      nixosModules = {
        default = self.nixosModules.nordvpn;
        nordvpn = import ./module.nix;
      };
    };
}
