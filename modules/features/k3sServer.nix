/**
# Feature Module: K3s Kubernetes Server (Control Plane)

## Description
Complete K3s Kubernetes control plane setup for self-hosted container orchestration.
Provides a production-ready, lightweight Kubernetes distribution optimized for
edge computing and development environments. Configured for high availability
with embedded etcd and flexible networking.

## Platform Support
- ✅ NixOS
- ❌ Darwin (K3s requires Linux kernel features)

## What This Enables
- **K3s Control Plane**: API server, scheduler, controller manager
- **Embedded etcd**: Distributed key-value store for cluster state
- **Container Runtime**: Containerd with K3s optimizations
- **Network Policy**: Flannel VXLAN backend for pod networking
- **Management Tools**: kubectl, helm, cluster administration utilities

## Configuration Features
- **Cluster Initialization**: Bootstrap mode for multi-node clusters
- **Disabled Components**: ServiceLB, Traefik, local-storage (for custom setups)
- **Security**: Proper kubeconfig permissions and firewall rules
- **High Availability**: etcd clustering support (ports 2379, 2380)
- **Agent Integration**: Automatic worker node labeling when k3sAgent enabled

## Network Configuration
- **6443**: Kubernetes API server
- **2379-2380**: etcd client/peer communication
- **8472**: Flannel VXLAN overlay network
- **10250**: kubelet metrics
- **30000-32767**: NodePort services (when agent enabled)

## Usage Notes
- Kubeconfig available at /etc/rancher/k3s/k3s.yaml
- 30-second startup delay ensures network readiness
- Compatible with k3sAgent module for single-node or multi-node clusters
- Disabled default ingress/load balancer for custom solutions
*/
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
          "--write-kubeconfig-mode 600"
          "--cluster-init"
          "--disable servicelb"
          "--disable traefik"
          "--disable local-storage"
          "--flannel-backend=vxlan"
        ]
        ++ lib.optionals config.myconfig.features.k3sAgent.enable [
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
          {
            from = 30000;
            to = 32767;
          } # NodePort services
        ];
      })
    ];

    environment.systemPackages = with pkgs; [
      k3s
      kubectl
      kubernetes-helm
    ];

    systemd.services.k3s = {
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        RestartSec = "5s";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 30";
      };
    };

    environment.variables = {
      KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    };
  };
}
