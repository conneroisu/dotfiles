{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.bluetooth";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [
        pkgs.blueman
      ];
      services.blueman.enable = true;
      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings = {
            General = {
              Name = "Hello";
              ControllerMode = "dual";
              FastConnectable = "true";
              Experimental = "true";
              Enable = "Source,Sink,Media,Socket";
            };
            Policy = {
              AutoEnable = "true";
            };
          };
        };
      };
    };
  }
