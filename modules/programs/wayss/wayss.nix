{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;

  # Create a proper Python package with test support
  python3Env = pkgs.python3.withPackages (ps:
    with ps; [
      ps.dbus-python
    ]);

  program =
    pkgs.writers.writePython3Bin "wayss" {
      flakeIgnore = ["W291" "W503" "E226" "E501" "W293"];
      libraries = with pkgs.python3Packages; [
        dbus-python
        pygobject3
      ];
    }
    ./main.py;
in
  delib.module {
    name = "programs.wayss";

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
