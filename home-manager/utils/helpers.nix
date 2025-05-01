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
  }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${platform};
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
        inputs.home-manager.flakeModules.default
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
