{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  # inputs,
  # Additional metadata is provided by Snowfall Lib.
  # namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  # home, # The home architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this home (eg. `x86_64-home`).
  # format, # A normalized name for the home target (eg. `home`).
  # virtual, # A boolean to determine whether this home is a virtual target using nixos-generators.
  # host, # The host name for this home.
  # All other arguments come from the home home.
  # config,
  ...
}: {
  snowfallorg.user = {
    name = "connerohnesorge";
    enable = true;
  };
  home.stateVersion = "24.05";
  nix.enable = pkgs.lib.mkDefault false;

  programs = {
    home-manager = {
      enable = true;
    };

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
        ui_font_size = pkgs.lib.mkDefault 16;
        buffer_font_size = pkgs.lib.mkDefault 16;
        telemetry.enable = pkgs.lib.mkDefault false;
        vim_mode = pkgs.lib.mkDefault true;
        theme = pkgs.lib.mkDefault {
          mode = "dark";
          dark = "One Dark";
          light = "One Light";
        };
      };
    };
  };

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyodark.yaml";
    image = ./../../../assets/klaus-desktop.jpeg;
    polarity = "dark";
    cursor = {
      name = "rose-pine-hyprcursor";
      size = 32;
      package = pkgs.rose-pine-hyprcursor;
    };
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

  services.mpris-proxy.enable = true;

  qt = {
    enable = true;
    platformTheme.name = pkgs.lib.mkDefault "adwaita";
    style.name = pkgs.lib.mkDefault "adwaita-dark";
    style.package = pkgs.adwaita-qt;
  };
}
