{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
  program =
    pkgs.writers.writePython3Bin "par" {
      flakeIgnore = ["W291" "W503" "E226"];
      libraries = [];
    }
    ./par.py;
in
  delib.module {
    name = "programs.par";

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
