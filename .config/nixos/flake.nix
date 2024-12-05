{
  description = "Conner Ohnesorge's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-ld = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:Mic92/nix-ld";
    };
    zen-browser.url = "github:conneroisu/zen-browser-flake";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nix-ld,
    nixos-hardware,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {allowUnfree = true;};
    };
    unstable-pkgs = import nixpkgs-unstable {
      inherit system;
      config = {allowUnfree = true;};
    };
    inputs = self.inputs;
    dbus = pkgs.dbus;
  in {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit system pkgs unstable-pkgs inputs;
        };
        modules = [
          ./configuration.nix
          nix-ld.nixosModules.nix-ld
          nixos-hardware.nixosModules.dell-xps-15-9510

          {programs.nix-ld.dev.enable = true;}
        ];
      };
    };
    stdenv.mkDerivation = {
      inherit dbus;
      nativeBuildInputs = [pkgs.pkg-config];
      buildInputs = with pkgs; [
        dbus
        webkitgtk
        openssl
      ];
    };
  };
}
