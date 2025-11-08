{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;

  program =
    pkgs.writers.writePython3Bin "pdf2md" {
      flakeIgnore = ["W291" "W503" "E226" "E501" "W293" "E265"];
      libraries = with pkgs.python3Packages; [
        desktop-notifier
        img2pdf
        openai
        pillow
        pymupdf
      ];
    }
    ./main.py;
in
  delib.module {
    name = "programs.pdf2md";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [program];
    };

    darwin.ifEnabled = {
      environment.systemPackages = [program];
    };
  }
