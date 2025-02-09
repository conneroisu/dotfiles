{
  config,
  pkgs,
  lib,
  stylix,
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

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyodark.yaml";
    image = ./Klaus-Desktop.png;
    polarity = "dark";
    targets.rofi.enable = true;
    targets.kitty.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = lib.mkForce "adw-gtk3-dark";
      package = lib.mkForce pkgs.adw-gtk3;
    };
    iconTheme.package = pkgs.papirus-icon-theme;
    iconTheme.name = "Papirus";

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
    style.package = pkgs.adwaita-qt;
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
