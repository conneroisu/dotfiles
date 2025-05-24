{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
  program =
    pkgs.writers.writeRubyBin "catls" {
      libraries = [
      ];
    } ''
      ${builtins.readFile ./catls.rb}
    '';
in
  delib.module {
    name = "programs.catls";

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
