{
  inputs,
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
  in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit
          inputs
          hostname
          platform
          username
          stateVersion
          ;
      };
      modules = [
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
