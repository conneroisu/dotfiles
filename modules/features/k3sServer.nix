{
  config,
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "features.k3sServer";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    services.k3s = {
      enable = true;
      role = "server";
      extraFlags = toString (
        [
          "--write-kubeconfig-mode 644"
          "--cluster-init"
          "--disable servicelb"
          "--disable traefik" 
          "--disable local-storage"
          "--flannel-backend=vxlan"
        ] ++ lib.optionals config.myconfig.features.k3sAgent.enable [
          "--node-label=node-role.kubernetes.io/worker=true"
        ]
      );
    };

    networking.firewall = lib.mkMerge [
      {
        allowedTCPPorts = [
          6443 # k3s: API server
          2379 # etcd clients (HA embedded etcd)
          2380 # etcd peers (HA embedded etcd)  
          10250 # kubelet metrics
        ];
        allowedUDPPorts = [
          8472 # flannel VXLAN
        ];
      }
      (lib.mkIf config.myconfig.features.k3sAgent.enable {
        allowedTCPPorts = [
          30000 # NodePort range start
          32767 # NodePort range end
        ];
        allowedTCPPortRanges = [
          { from = 30000; to = 32767; } # NodePort services  
        ];
      })
    ];

    environment.systemPackages = with pkgs; [
      k3s
      kubectl
      kubernetes-helm
    ];

    systemd.services.k3s.after = [ "network-online.target" ];
    systemd.services.k3s.wants = [ "network-online.target" ];

    environment.variables = {
      KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    };
  };
}