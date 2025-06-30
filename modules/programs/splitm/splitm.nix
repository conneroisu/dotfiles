{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
  program =
    pkgs.writers.writePython3Bin "splitm" {
      flakeIgnore = [
        "E501"
        "W503"
        "W391"
      ];
    } ''
      ${builtins.readFile ./splitm.py}
    '';
in
  delib.module {
    name = "programs.splitm";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [
        program
      ];
    };

    darwin.ifEnabled = {
      environment.systemPackages = [
        program
      ];
    };
  }
