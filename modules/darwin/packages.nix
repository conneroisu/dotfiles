{ pkgs, unstable-pkgs, ... }:

let shared-packages = import ../shared/packages.nix { inherit pkgs unstable-pkgs; }; in
shared-packages ++ [
  pkgs.fswatch
  pkgs.dockutil
  pkgs.aerospace
]
