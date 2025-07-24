{ pkgs, ... }: {
  # Exported package sets for shared use across features
  cliTools = import ./cli-tools.nix { inherit pkgs; };
  development = import ./development.nix { inherit pkgs; };
  editors = import ./editors.nix { inherit pkgs; };
  networking = import ./networking.nix { inherit pkgs; };
  containers = import ./containers.nix { inherit pkgs; };
  languages = import ./languages.nix { inherit pkgs; };
  applications = import ./applications.nix { inherit pkgs; };
}