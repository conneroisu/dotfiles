{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # You also have access to your flake's inputs.
  inputs,
  # The namespace used for your flake, defaulting to "internal" if not set.
  namespace,
  # All other arguments come from NixPkgs. You can use `pkgs` to pull packages or helpers
  # programmatically or you may add the named attributes as arguments here.
  pkgs,
  stdenv,
  ...
}: let
  baseUrl = "https://github.com/zen-browser/desktop/releases/download";
  pname = "zen-browser";
  description = "Zen Browser: Experience tranquillity while browsing the web without people tracking you!";
  supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-darwin" "aarch64-linux"];
  forAllSystems = inputs.nixpkgs.lib.genAttrs supportedSystems;
  version = "1.0.2-b.5";
  downloadUrl = {
    "x86_64-linux" = {
      url = "${baseUrl}/${version}/zen.linux-x86_64.tar.bz2";
      sha256 = "sha256:1xp0z86l7z661cwckgr623gwwjsy3h66900xqjq6dvgx5a3njbxi";
    };
    "aarch64-linux" = {
      url = "${baseUrl}/${version}/zen.linux-aarch64.tar.bz2";
      sha256 = "sha256:1dm7la05ym41my837iyh469ccyxzf776v26hh1q835h17i3r5qcy";
    };
    "aarch64-darwin" = {
      url = "${baseUrl}/${version}/zen.macos-aarch64.dmg";
      sha256 = "sha256:0xdc7g6ksirmrq4vmdrvk4l09sk63psdqr9dqqc9dx51gyf47g0a";
    };
    "x86_64-darwin" = {
      url = "${baseUrl}/${version}/zen.macos-x86_64.dmg";
      sha256 = "sha256:0kk7wq90xd4ccd7kkjw64ckrvwwc6wbfa51r9w99q0l3fmzzjya3";
    };
  };

  pkgsForSystem = system: import inputs.nixpkgs {inherit system;};

  linuxRuntimeLibs = pkgs:
    with pkgs;
      [
        libGL
        libGLU
        libevent
        libffi
        libjpeg
        libpng
        libstartup_notification
        libvpx
        libwebp
        stdenv.cc.cc
        fontconfig
        libxkbcommon
        zlib
        freetype
        gtk3
        libxml2
        dbus
        xcb-util-cursor
        alsa-lib
        libpulseaudio
        pango
        atk
        cairo
        gdk-pixbuf
        glib
        udev
        libva
        mesa
        libnotify
        cups
        pciutils
        ffmpeg
        libglvnd
        pipewire
      ]
      ++ (with pkgs.xorg; [
        libxcb
        libX11
        libXcursor
        libXrandr
        libXi
        libXext
        libXcomposite
        libXdamage
        libXfixes
        libXScrnSaver
      ]);

  mkZen = system: let
    pkgs = pkgsForSystem system;
    inherit (pkgs) stdenv;
    inherit (stdenv) isDarwin;
    downloadData = downloadUrl."${system}";
  in
    stdenv.mkDerivation {
      inherit version pname description;

      src =
        if isDarwin
        then
          pkgs.fetchurl {
            inherit (downloadData) url sha256;
            name = "zen-${version}.dmg";
          }
        else
          builtins.fetchTarball {
            inherit (downloadData) url sha256;
          };

      desktopSrc = ./.;

      phases =
        if isDarwin
        then ["unpackPhase" "installPhase"]
        else ["installPhase" "fixupPhase"];

      nativeBuildInputs = with pkgs;
        [
          makeWrapper
          copyDesktopItems
        ]
        ++ (
          if isDarwin
          then [undmg]
          else [wrapGAppsHook]
        );

      unpackPhase = pkgs.lib.optionalString isDarwin ''
        undmg $src
      '';

      installPhase =
        if isDarwin
        then ''
          mkdir -p $out/Applications
          cp -r "Zen Browser.app" $out/Applications/
        ''
        else ''
          mkdir -p $out/bin && cp -r $src/* $out/bin
          install -D $desktopSrc/zen.desktop $out/share/applications/zen.desktop
          install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png
        '';

      fixupPhase = pkgs.lib.optionalString (!isDarwin) ''
        chmod 755 $out/bin/*
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen
        wrapProgram $out/bin/zen --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath (linuxRuntimeLibs pkgs)}" \
                        --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --set MOZ_APP_LAUNCHER zen --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen-bin
        wrapProgram $out/bin/zen-bin --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath (linuxRuntimeLibs pkgs)}" \
                        --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --set MOZ_APP_LAUNCHER zen --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/glxtest
        wrapProgram $out/bin/glxtest --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath (linuxRuntimeLibs pkgs)}"
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/updater
        wrapProgram $out/bin/updater --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath (linuxRuntimeLibs pkgs)}"
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/vaapitest
        wrapProgram $out/bin/vaapitest --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath (linuxRuntimeLibs pkgs)}"
      '';

      meta = {
        mainProgram =
          if isDarwin
          then null
          else "zen";
        platforms = [system];
      };
    };
in {
  packages = forAllSystems (system: {
    default = mkZen system;
  });
}
