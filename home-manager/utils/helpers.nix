{
  inputs,
  outputs,
  stateVersion,
  ...
}: {
  # Helper function for generating home-manager configs
  mkHome = {
    hostname ? "nixos",
    username ? "nixos",
    platform ? "x86_64-linux",
  }: let
    pkgs = inputs.nixpkgs.legacyPackages.${platform};
    mod =
      if pkgs.stdenv.isDarwin
      then inputs.home-manager.darwinModules.default
      else inputs.home-manager.nixosModules.default;
  in
    inputs.home-manager.lib.homeManagerConfiguration {
      extraSpecialArgs = {
        inherit
          inputs
          outputs
          hostname
          platform
          username
          stateVersion
          ;
      };
      modules = [
        mod
        ../.
      ];
    };

  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];
}
