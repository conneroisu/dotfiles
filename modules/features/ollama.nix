/**
TODO: Add documentation
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.ollama";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      environment.systemPackages = with pkgs; [
        ollama
      ];

      services = {
        ollama = {
          enable = true;
          loadModels = ["gpt-oss:20b"];
          acceleration =
            if myconfig.features.amd.enable
            then "rocm"
            else if myconfig.features.nvidia.enable
            then "nvidia"
            else "cpu";
        };
        open-webui.enable = true;
      };
    };
  }
