{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
  program = pkgs.writeShellApplication {
    name = "md2pdf";
    text = ''
      input=$1
      output="$(basename "$input" .md).pdf"
      pandoc "$input" \
        -o "$output" \
        --standalone \
        --pdf-engine=xelatex \
        --highlight-style=kate \
        --embed-resources \
        --css=${./default.css} \
        --lua-filter=${./default.lua} \
        --mathjax \
        -V mainfont="Times New Roman" \
        -V monofont="CodeNewRoman Nerd Font" \
        -V fontsize=11pt \
        -V geometry:margin=1in \
        -V linkcolor=blue
    '';
    runtimeInputs = [
      pkgs.pandoc
      pkgs.texliveSmall
    ];
  };
in
  delib.module {
    name = "programs.md2pdf";

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
