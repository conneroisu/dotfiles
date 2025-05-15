{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "programs.catls";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      environment.systemPackages = with pkgs; [
        (
          pkgs.writers.writeRubyBin "catls" {
            libraries = [
            ];
          } ''
            ${builtins.readFile ./catls.rb}
          ''
        )
      ];
    };
  }
