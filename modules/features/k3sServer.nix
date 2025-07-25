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
      extraFlags = toString [
        "--write-kubeconfig-mode 644"
        "--cluster-init"
        "--disable servicelb"
        "--disable traefik" 
        "--disable local-storage"
        "--flannel-backend=vxlan"
      ];
    };

    networking.firewall = {
      allowedTCPPorts = [
        6443 # k3s: API server
        2379 # etcd clients (HA embedded etcd)
        2380 # etcd peers (HA embedded etcd)  
        10250 # kubelet metrics
      ];
      allowedUDPPorts = [
        8472 # flannel VXLAN
      ];
      # NodePort range for services (optional, can be restricted per deployment)
      allowedTCPPortRanges = [
        { from = 30000; to = 32767; } # NodePort services  
      ];
    };

    environment.systemPackages = with pkgs; [
      k3s
      kubectl
      kubernetes-helm
    ];

    systemd.services.k3s = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        RestartSec = "5s";
        # Wait for network stabilization before starting k3s server
        # Prevents issues with cluster initialization on slow network startup
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 30";
      };
    };

    environment.variables = {
      KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    };
  };
}