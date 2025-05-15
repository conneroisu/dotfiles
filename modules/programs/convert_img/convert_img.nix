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
      environment.systemPackages = with pkgs; [
        (
          pkgs.writers.writePython3Bin "convert_img" {
            libraries = [
              pkgs.python3Packages.pillow
            ];
          }
          ./convert_img.py
        )
      ];
    };
  }
