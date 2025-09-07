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

  explorer-program = pkgs.kdePackages.dolphin;

  program = pkgs.writeShellScriptBin "explorer" ''
    ${pkgs.lib.getExe explorer-program}
  '';

  supporting-pkgs = with pkgs; [
    lxmenu-data
  ];

  supporting-kde-pkgs = with pkgs.kdePackages; [
    kactivitymanagerd
    plasma-workspace
    kservice
    kded
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
