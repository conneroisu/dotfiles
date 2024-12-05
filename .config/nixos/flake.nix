{
  description = "Conner Ohnesorge's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    nix-ld = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:Mic92/nix-ld";
    };
    zen-browser.url = "github:conneroisu/zen-browser-flake";
  };

  outputs = {
    self,
    nixpkgs,
    nix-ld,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };
  in {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit system;
          inputs = self.inputs;
        };
        modules = [
          ./configuration.nix
          nix-ld.nixosModules.nix-ld

          {programs.nix-ld.dev.enable = true;}
        ];
      };
    };
    templates = {
      bar = {
        path = ./my-bar-project;
        description = "Example of a Fabric bar using Nix";
        welcomeText = '''';
      };
    };
    stdenv.mkDerivation = {
      nativeBuildInputs = [pkgs.pkg-config];
      buildInputs = with pkgs; [
        dbus
        webkitgtk
        openssl
      ];
      dbus = pkgs.dbus;
    };
  };
}
