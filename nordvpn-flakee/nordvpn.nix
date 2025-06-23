{
  autoPatchelfHook,
  buildFHSEnvChroot,
  dpkg,
  fetchurl,
  lib,
  stdenv,
  sysctl,
  iptables,
  iproute2,
  procps,
  cacert,
  libxml2,
  libidn2,
  zlib,
  wireguard-tools,
}: let
  pname = "nordvpn";
  version = "3.18.3";

  nordVPNBase = stdenv.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn_${version}_amd64.deb";
      hash = "sha256-pCveN8cEwEXdvWj2FAatzg89fTLV9eYehEZfKq5JdaY=";
    };

    buildInputs = [libxml2 libidn2];
    nativeBuildInputs = [dpkg autoPatchelfHook stdenv.cc.cc.lib];

    dontConfigure = true;
    dontBuild = true;

    unpackPhase = ''
      runHook preUnpack
      dpkg --extract $src .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      mv usr/* $out/
      mv var/ $out/
      mv etc/ $out/
      runHook postInstall
    '';
  };

  nordVPNfhs = buildFHSEnvChroot {
    name = "nordvpnd";
    runScript = "nordvpnd";

    targetPkgs = pkgs: [
      nordVPNBase
      sysctl
      iptables
      iproute2
      procps
      cacert
      libxml2
      libidn2
      zlib
      wireguard-tools
    ];
  };
in
  stdenv.mkDerivation {
    inherit pname version;

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/share
      ln -s ${nordVPNBase}/bin/nordvpn $out/bin
      ln -s ${nordVPNfhs}/bin/nordvpnd $out/bin
      ln -s ${nordVPNBase}/share/* $out/share/
      ln -s ${nordVPNBase}/var $out/
      runHook postInstall
    '';

    meta = with lib; {
      description = "CLI client for NordVPN";
      homepage = "https://www.nordvpn.com";
      license = licenses.unfreeRedistributable;
      platforms = ["x86_64-linux" "aarch64-linux"];
    };
  }
