{
  description = "Home Manager configuration of connerohnesorge";

  inputs = {
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
  }: {
    homeConfigurations = {
      # macOS configuration
      "connerohnesorge@Conners-MacBook-Air.local" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin; # Assuming M1/M2 Mac, use x86_64-darwin for Intel
        modules = [
          ./home-darwin.nix
        ];
      };

      # Linux configuration
      "connerohnesorge" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          stylix.homeManagerModules.stylix
          ./home.nix
        ];
      };
    };
  };
}
