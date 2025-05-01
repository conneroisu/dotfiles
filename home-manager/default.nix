{
  lib,
  pkgs,
  stateVersion,
  username,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin isLinux;
in {
  home = {
    inherit stateVersion;
    inherit username;
    homeDirectory =
      if isDarwin
      then "/Users/${username}"
      else "/home/${username}";

    packages = with pkgs;
      [
        cpufetch
        fastfetch
        ipfetch
        onefetch
        micro
      ]
      ++ lib.optionals isLinux [
        ramfetch
      ]
      ++ lib.optionals isDarwin [
        m-cli
      ];
    sessionVariables = {
      EDITOR = "micro";
      SYSTEMD_EDITOR = "micro";
      VISUAL = "micro";
    };

    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyodark.yaml";
      image = ./../../../assets/klaus-desktop.jpeg;
      polarity = "dark";
      cursor = {
        size = 12;
        name = "rose-pine-hyprcursor";
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
  };

  # Workaround home-manager bug
  # - https://github.com/nix-community/home-manager/issues/2033
  news = {
    display = "silent";
    entries = lib.mkForce [];
  };

  nix = {
    package = pkgs.nixVersions.latest;
  };

  programs = {
    zsh.enable = true;
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
    micro = {
      enable = true;
      settings = {
        autosu = true;
        diffgutter = true;
        paste = true;
        rmtrailingws = true;
        savecursor = true;
        saveundo = true;
        scrollbar = true;
        scrollbarchar = "░";
        scrollmargin = 4;
        scrollspeed = 1;
      };
    };
  };
}
