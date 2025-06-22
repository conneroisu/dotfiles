{
  delib,
  pkgs,
  config,
  ...
}: let
  inherit (delib) singleEnableOption;
  nordVpnPkg = pkgs.callPackage (
    { stdenv, lib, fetchurl, openvpn, libxml2, autoPatchelfHook, dpkg,... }:

stdenv.mkDerivation rec {
  pname = "nordvpn";
  version = "3.10.0-1";

  src = fetchurl {
    url = "https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn_${version}_amd64.deb";
    sha256 = "BNAInjJlQsYpxfUKI13oK/P6n6gpBlvgSQoJAuZ3C2M=";
  };

  nativeBuildInputs = [ libxml2 autoPatchelfHook dpkg ];

  unpackPhase = ''
    dpkg -x $src unpacked
  '';

  installPhase = ''
    mkdir -p $out/
    sed -i 's;ExecStart=.*;;g' unpacked/usr/lib/systemd/system/nordvpnd.service
    cp -r unpacked/* $out/
    mv $out/usr/* $out/
    mv $out/sbin/nordvpnd $out/bin/
    rm -r $out/sbin
    rm $out/var/lib/nordvpn/openvpn
    ln -s ${openvpn}/bin/openvpn $out/var/lib/nordvpn/openvpn
  '';

  meta = with lib; {
    description = "NordVPN: Best VPN service. Online security starts with a click";
    downloadPage = "https://nordvpn.com/download/";
    homepage = "https://nordvpn.com/";
    license = licenses.unfree;
    maintainers = with maintainers; [ juliosueiras ];
    platforms = platforms.linux;
  };});
in
  delib.module {
    name = "programs.nordvpn";
    options = singleEnableOption false;
    # options.myypo.services.custom.nordvpn.enable = mkOption {
    #   type = types.bool;
    #   default = false;
    #   description = ''
    #     Whether to enable the NordVPN daemon. Note that you'll have to set
    #     `networking.firewall.checkReversePath = false;`, add UDP 1194
    #     and TCP 443 to the list of allowed ports in the firewall and add your
    #     user to the "nordvpn" group (`users.users.<username>.extraGroups`).
    #   '';
    # };

    nixos.ifEnabled = {
      networking.firewall.checkReversePath = false;

      environment.systemPackages = [nordVpnPkg];

      users.groups.nordvpn = {};
      users.groups.nordvpn.members = [config.constants.username];
      systemd = {
        services.nordvpn = {
          description = "NordVPN daemon.";
          serviceConfig = {
            ExecStart = "${nordVpnPkg}/bin/nordvpnd";
            ExecStartPre = pkgs.writeShellScript "nordvpn-start" ''
              mkdir -m 700 -p /var/lib/nordvpn;
              if [ -z "$(ls -A /var/lib/nordvpn)" ]; then
                cp -r ${nordVpnPkg}/var/lib/nordvpn/* /var/lib/nordvpn;
              fi
            '';
            NonBlocking = true;
            KillMode = "process";
            Restart = "on-failure";
            RestartSec = 5;
            RuntimeDirectory = "nordvpn";
            RuntimeDirectoryMode = "0750";
            Group = "nordvpn";
          };
          wantedBy = ["multi-user.target"];
          after = ["network-online.target"];
          wants = ["network-online.target"];
        };
      };
    };
  }
