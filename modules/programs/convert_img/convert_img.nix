{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "programs.convert_img";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      environment.systemPackages = [
        (
          pkgs.writers.writePython3Bin "convert_img" {
            flakeIgnore = ["W291" "W503" "E226"];
            libraries = [
              pkgs.python3Packages.pillow
            ];
          }
          ./convert_img.py
        )
      ];
    };
  }
