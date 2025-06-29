/**
  # Program Module: md2pdf (Markdown to PDF Converter)
  
  ## Description
  A sophisticated Markdown to PDF converter using Pandoc with XeLaTeX backend.
  Produces professionally formatted PDFs from Markdown files with support for
  mathematical notation, syntax highlighting, custom styling, and embedded
  resources.
  
  ## Platform Support
  - ✅ NixOS
  - ✅ Darwin
  
  ## Features
  - High-quality PDF output via XeLaTeX
  - Mathematical formula rendering (MathJax)
  - Syntax highlighting for code blocks
  - Custom CSS styling
  - Lua filters for advanced processing
  - Embedded resources (images, fonts)
  - Professional typography
  
  ## Implementation
  - **Engine**: Pandoc with XeLaTeX
  - **Styling**: Custom CSS (./default.css)
  - **Filters**: Lua filter (./default.lua)
  - **Fonts**: Times New Roman + CodeNewRoman Nerd Font
  
  ## Document Features
  - **Typography**: Professional fonts and spacing
  - **Code Blocks**: Kate syntax highlighting theme
  - **Math Support**: Full LaTeX math notation
  - **Links**: Blue hyperlinks
  - **Layout**: 1-inch margins, 11pt font
  - **Resources**: All images/assets embedded
  
  ## Usage
  ```bash
  md2pdf document.md              # Creates document.pdf
  md2pdf README.md                # Creates README.pdf
  md2pdf notes/lecture.md         # Creates lecture.pdf
  ```
  
  ## Output Configuration
  - Main font: Times New Roman
  - Code font: CodeNewRoman Nerd Font
  - Font size: 11pt
  - Margins: 1 inch all sides
  - Link color: Blue
  - Standalone document with all dependencies
  
  ## Common Use Cases
  - Technical documentation
  - Academic papers and reports
  - Project documentation
  - Meeting notes and presentations
  - README files for offline viewing
  - Code documentation with examples
  
  ## Advanced Features
  - Custom Lua filters for processing
  - CSS customization support
  - MathJax for complex equations
  - Cross-references and citations
  - Table of contents generation
  
  ## Dependencies
  - pandoc: Document conversion engine
  - texliveSmall: LaTeX distribution
  - XeLaTeX: Modern TeX engine
  
  ## Configuration
  Enabled via:
  - `myconfig.programs.md2pdf.enable = true`
  - Or automatically with engineer feature
*/
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
