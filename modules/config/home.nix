{
  delib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin isLinux;
in
  delib.module {
    name = "home";

    home.always = {myconfig, ...}: let
      inherit (myconfig.constants) username;
    in {
      gtk =
        if isLinux
        then {
          enable = true;
          theme = {
            name = pkgs.lib.mkForce "adw-gtk3-dark";
            package = pkgs.lib.mkForce pkgs.adw-gtk3;
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
        }
        else {};

      # Workaround home-manager bug
      # - https://github.com/nix-community/home-manager/issues/2033
      news = {
        display = "silent";
        entries = pkgs.lib.mkForce [];
      };

      programs.home-manager.enable = true;

      services.mpris-proxy.enable =
        if isLinux
        then true
        else false;
      home = {
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
          ]
          ++ lib.optionals isLinux [
            ramfetch
          ]
          ++ lib.optionals isDarwin [
            m-cli
          ];
        sessionVariables = {
          EDITOR = "nvim";
          SYSTEMD_EDITOR = "nvim";
          VISUAL = "nvim";
        };
      };
    };
  }
