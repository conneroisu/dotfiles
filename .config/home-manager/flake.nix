{
  description = "Conner Ohnesorge's home-manager Configuration";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-24.11";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
    }:
    {
      homeConfigurations = {
        "connerohnesorge@nixos" = home-manager.lib.homeManagerConfiguration ({
          modules = [ ./linux.nix ./home.nix ];
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        });

        "connerohnesorge@your-mac" = home-manager.lib.homeManagerConfiguration ({
          modules = [ import ./darwin.nix ./home.nix ];
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfree = true;
          };
        });
      };
    };
}
