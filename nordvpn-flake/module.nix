{
  config,
  lib,
  pkgs,
  ...
}: let
  nordVpnPkg = pkgs.callPackage ./nordvpn.nix {};
in
  with lib; {
    options.services.nordvpn = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the NordVPN daemon. Note that you'll have to set
          `networking.firewall.checkReversePath = false;`, add UDP 1194
          and TCP 443 to the list of allowed ports in the firewall and add your
          user to the "nordvpn" group.
        '';
      };

      users = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          List of users to add to the nordvpn group.
        '';
      };
    };

    config = mkIf config.services.nordvpn.enable {
      networking.firewall = {
        checkReversePath = false;
        allowedTCPPorts = [443];
        allowedUDPPorts = [1194];
      };

      environment.systemPackages = [nordVpnPkg];

      users.groups.nordvpn = {};
      users.users = lib.genAttrs config.services.nordvpn.users (user: {
        extraGroups = ["nordvpn"];
      });

      systemd.services.nordvpn = {
        description = "NordVPN daemon";
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
  }