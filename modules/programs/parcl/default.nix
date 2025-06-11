{
  delib,
  # inputs,
  # system,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "programs.parcl";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [
        # inputs.parcl.packages.${system}.default
      ];
    };
    darwin.ifEnabled = {
      environment.systemPackages = [
        # inputs.parcl.packages.${system}.default
      ];
    };
  }
