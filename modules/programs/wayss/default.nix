{
  lib ? (import <nixpkgs> {}).lib,
  pkgs ? import <nixpkgs> {},
  stdenv ? pkgs.stdenv,
  python3 ? pkgs.python3,
  python3Packages ? pkgs.python3Packages,
  makeWrapper ? pkgs.makeWrapper,
  wrapGAppsHook ? pkgs.wrapGAppsHook,
  gobject-introspection ? pkgs.gobject-introspection,
  gtk3 ? pkgs.gtk3,
  grim ? pkgs.grim,
  slurp ? pkgs.slurp,
  wl-clipboard ? pkgs.wl-clipboard,
  dunst ? pkgs.dunst,
  glib ? pkgs.glib,
}: let
  # Python environment with all required dependencies
  pythonEnv = python3.withPackages (ps:
    with ps; [
      dbus-python
      pygobject3
    ]);
in
  stdenv.mkDerivation rec {
    pname = "wayss";
    version = "1.0.0";

    src = ./.;

    nativeBuildInputs = [
      makeWrapper
      wrapGAppsHook
      gobject-introspection
    ];

    buildInputs = [
      pythonEnv
      gtk3
      glib
      gobject-introspection
      # Runtime dependencies that the script expects to find
      grim
      slurp
      wl-clipboard
      dunst
    ];

    # Disable stripping to avoid issues with Python bytecode
    dontStrip = true;

    buildPhase = ''
      runHook preBuild
      
      # Validate Python syntax
      ${pythonEnv}/bin/python -m py_compile main.py
      
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      
      mkdir -p $out/bin
      cp main.py $out/bin/wayss
      chmod +x $out/bin/wayss
      
      runHook postInstall
    '';

    postFixup = ''
      # Wrap the script to ensure all dependencies are in PATH and Python can find GTK
      wrapProgram $out/bin/wayss \
        --prefix PATH : ${lib.makeBinPath [grim slurp wl-clipboard dunst]} \
        --prefix PYTHONPATH : ${pythonEnv}/${pythonEnv.sitePackages} \
        --set GI_TYPELIB_PATH ${glib}/lib/girepository-1.0:${gtk3}/lib/girepository-1.0:${gobject-introspection}/lib/girepository-1.0 \
        --prefix XDG_DATA_DIRS : ${gtk3}/share/gsettings-schemas/${gtk3.name}:${glib}/share
    '';

    # Tests to validate the build  
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      
      # Test basic Python import only (GTK test will be done at runtime)
      ${pythonEnv}/bin/python -c "
      import sys
      sys.path.insert(0, '.')
      
      # Test individual imports
      import dbus
      print('✓ dbus imported successfully')
      
      import gi
      print('✓ gi imported successfully')
      
      print('✓ Basic dependencies available')
      "
      
      runHook postCheck
    '';

    meta = with lib; {
      description = "Hyprland Screenshot Tool with Recent Files Integration";
      longDescription = ''
        A comprehensive screenshot utility for Hyprland that:
        - Takes region screenshots using grim/slurp
        - Copies screenshots to clipboard via wl-copy
        - Saves timestamped screenshots to ~/Pictures/Screenshots/
        - Adds screenshots to system recent files for easy access
        - Provides rich D-Bus notifications for all operations
        - Falls back gracefully when dependencies are unavailable
      '';
      homepage = "https://github.com/conneroisu/dotfiles";
      license = licenses.publicDomain;
      maintainers = with maintainers; [];
      platforms = platforms.linux;
      mainProgram = "wayss";
    };
  }