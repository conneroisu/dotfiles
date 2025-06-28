/**
  # Feature Module: Student Tools
  
  ## Description
  Academic and educational software suite for students. Provides essential
  tools for document creation, research, and academic work. Currently
  includes LibreOffice with room for expansion to other academic tools.
  
  ## Platform Support
  - ✅ NixOS
  - ✅ Darwin (prepared but no packages defined yet)
  
  ## What This Enables
  - **LibreOffice**: Complete office suite for documents, spreadsheets, presentations
  
  ## LibreOffice Components
  - Writer: Word processing for essays and reports
  - Calc: Spreadsheet for data analysis and calculations
  - Impress: Presentations for academic projects
  - Draw: Vector graphics and diagrams
  - Math: Formula editor for scientific notation
  - Base: Database management for research data
  
  ## Potential Additions
  - Note-taking applications (Obsidian, Logseq)
  - Reference managers (Zotero, Mendeley)
  - LaTeX environment for academic papers
  - Scientific calculators and plotting tools
  - Mind mapping software
  - PDF annotation tools
  - Language learning applications
  
  ## File Format Support
  - Native ODF formats (.odt, .ods, .odp)
  - Microsoft Office compatibility (.docx, .xlsx, .pptx)
  - PDF export with embedded fonts
  - Legacy format support
  
  ## Common Use Cases
  - Writing academic papers and essays
  - Creating presentations for classes
  - Data analysis for research projects
  - Collaborative document editing
  - Creating study materials
  - Managing bibliographies
  
  ## Academic Workflow
  - Document templates for common formats
  - Citation and bibliography support
  - Track changes for peer review
  - Export to standard academic formats
  
  ## Note
  This module is designed to be extended with additional
  academic tools based on specific field requirements
  (STEM, humanities, social sciences, etc.)
*/
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
