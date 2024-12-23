{
  description = "Home Manager configuration of connerohnesorge";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    stylix.url = "github:danth/stylix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    stylix,
    home-manager,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    homeConfigurations = {
      connerohnesorge = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules =
          if pkgs.stdenv.isDarwin
          then [
            ./home.nix
          ]
          else [
            stylix.homeManagerModules.stylix
            ./home.nix
          ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
    };
  };
}
