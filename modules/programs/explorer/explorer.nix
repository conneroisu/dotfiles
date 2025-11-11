# $HOME/.local/share/kactivitymanagerd/resources/database
/*
TODO: Add comment
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;

  explorer-program = pkgs.kdePackages.dolphin.overrideAttrs (oldAttrs: {
    meta.mainProgram = "dolphin";
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
    postInstall =
      (oldAttrs.postInstall or "")
      + ''
        wrapProgram $out/bin/dolphin \
            --set XDG_CONFIG_DIRS "${pkgs.libsForQt5.kservice}/etc/xdg:$XDG_CONFIG_DIRS" \
            --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath (with pkgs; [
          pipewire
          kdePackages.qtmultimedia
          kdePackages.qtbase
        ])} \
            --run "${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental ${pkgs.libsForQt5.kservice}/etc/xdg/menus/applications.menu"
      '';
  });
  program = pkgs.writeShellScriptBin "explorer" ''
    ${pkgs.lib.getExe explorer-program} $@
  '';

  supporting-pkgs = with pkgs; [
    lxmenu-data
  ];

  supporting-kde-pkgs = with pkgs.kdePackages; [
    kactivitymanagerd
    plasma-workspace
    kservice
    kded
    kio-admin
    kio-fuse
  ];

  supporting-libs = with pkgs.libsForQt5; [
    kactivities
    kactivities-stats
  ];
in
  delib.module {
    name = "programs.explorer";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages =
        [
          explorer-program
          program
        ]
        ++ supporting-pkgs ++ supporting-libs ++ supporting-kde-pkgs;
      services.dbus.packages = with pkgs; [
        kdePackages.kactivitymanagerd # provides the org.kde.ActivityManager service file
      ];
    };

    darwin.ifEnabled = {};
  }
