{
  delib,
  inputs,
  # system,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "programs.proton-x";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [
        pkgs.protonmail-desktop
        pkgs.proton-pass

        inputs.proton-authenticator.packages."${pkgs.stdenv.hostPlatform.system}".default
      ];
    };
    darwin.ifEnabled = {
      # macOS packages can be added when needed
    };
  }
