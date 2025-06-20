{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
  program =
    pkgs.writers.writePython3Bin "convert_media" {
      flakeIgnore = ["W291" "W503" "E226" "E501"];
    }
    ./convert_media.py;
in
  delib.module {
    name = "programs.convert_media";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [
        program
        pkgs.ffmpeg
      ];
    };

    darwin.ifEnabled = {
      environment.systemPackages = [
        program
        pkgs.ffmpeg
      ];
    };
  }
