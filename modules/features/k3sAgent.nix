/**
# Feature Module: K3s Kubernetes Agent Node

## Description
Lightweight Kubernetes agent node configuration using K3s. Provides worker node
capabilities for joining existing K3s clusters or running as a standalone agent.
Includes networking configuration and tooling for container orchestration.

## Platform Support
- ✅ NixOS
- ❌ Darwin (K3s agent requires Linux kernel features)

## What This Enables
- **K3s Agent**: Lightweight Kubernetes worker node
- **Network Configuration**: NodePort service access (ports 30000-32767)
- **Container Runtime**: Containerd with K3s optimizations
- **Kubernetes Tools**: kubectl, helm for cluster management
- **Service Mesh Ready**: Flannel VXLAN backend for pod networking

## Usage Notes
- Automatically detects if k3sServer module is enabled to avoid conflicts
- Standalone mode: Connects to local server at 127.0.0.1:6443
- Worker mode: Additional networking and tooling without conflicting services
- Kubeconfig automatically configured at /etc/rancher/k3s/k3s.yaml
- Requires network connectivity to K3s server for cluster joining

## Dependencies
- Network connectivity for cluster communication
- Sufficient resources for container workloads
- Firewall configuration for NodePort services
*/
{
  config,
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "features.k3sAgent";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    # Only configure additional networking and features when enabled
    # The actual k3s service is configured by k3sServer module

    networking.firewall = lib.mkMerge [
      {
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
      }
    ];

    # Add worker node specific packages if needed
    environment.systemPackages = lib.mkIf (!config.myconfig.features.k3sServer.enable) (with pkgs; [
      k3s
      kubectl
      kubernetes-helm
    ]);

    # If k3sAgent is enabled without k3sServer, configure as standalone agent
    services.k3s = lib.mkIf (!config.myconfig.features.k3sServer.enable) {
      enable = true;
      role = "agent";
      serverAddr = "https://127.0.0.1:6443";
      extraFlags = toString [
        "--write-kubeconfig-mode 600"
        "--flannel-backend=vxlan"
      ];
    };

    systemd.services.k3s = lib.mkIf (!config.myconfig.features.k3sServer.enable) {
      after = ["network-online.target"];
      wants = ["network-online.target"];
    };

    environment.variables = lib.mkIf (!config.myconfig.features.k3sServer.enable) {
      KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    };
  };
}
