{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  home, # The home architecture for this host (eg. `x86_64-linux`).
  target, # The Snowfall Lib target for this home (eg. `x86_64-home`).
  format, # A normalized name for the home target (eg. `home`).
  virtual, # A boolean to determine whether this home is a virtual target using nixos-generators.
  host, # The host name for this home.
  # All other arguments come from the home home.
  config,
  ...
}: {
  snowfallorg.user = {
    name = "connerohnesorge";
    enable = true;
  };

  home.stateVersion = "24.05";

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