{
  config,
  pkgs,
  lib,
  ...
}: {
  home = {
    username = "connerohnesorge";
    homeDirectory = "/home/connerohnesorge";

    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "24.05"; # Please read the comment before changing.
  };

  # Let Home Manager install and manage itself.
  programs = {
    zed-editor = {
      enable = true;
      extensions = [
        "nix"
        "dockerfile"
        "toml"
        "html"
        "templ"
        "latex"
        "svelte"
        "golangci-lint"
        "astro"
        "python-lsp"
        "ocaml"
        "vhdl"
        "verilog"
      ];
      userSettings = {
        ui_font_size = 16;
        buffer_font_size = 16;
        telemetry.enable = false;
        vim_mode = true;
        theme = {
          mode = "dark";
          dark = "One Dark";
          light = "One Light";
        };
      };
    };
    home-manager.enable = true;
  };
}
