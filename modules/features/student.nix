{
  delib,
  pkgs,
  inputs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.student";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment = {
        systemPackages = with pkgs; [
          libreoffice
        ];
      };
    };

    darwin.ifEnabled = {
    };
  }
