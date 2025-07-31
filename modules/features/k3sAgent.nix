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
- **IMPORTANT**: Requires authentication token/tokenFile for cluster access

## Authentication
- Use `config.myconfig.k3s.tokenFile` to specify token file path
- Token file should contain the cluster join token
- For security, token should be managed via secrets management (SOPS)

## Dependencies
- Network connectivity for cluster communication
- Sufficient resources for container workloads
- Firewall configuration for NodePort services
- Authentication token for cluster joining
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
  options = {
    myconfig.features.k3sAgent = delib.singleEnableOption false;
    
    # Additional k3s agent configuration options
    myconfig.k3s = {
      serverAddr = lib.mkOption {
        type = lib.types.str;
        default = "https://127.0.0.1:6443";
        description = "Address of the k3s server to connect to";
      };
      
      tokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to file containing the k3s agent token";
        example = "/run/secrets/k3s-token";
      };
      
      token = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "k3s agent token (prefer tokenFile for security)";
      };
    };
  };

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
          { from = 30000; to = 32767; } # NodePort services
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
      serverAddr = config.myconfig.k3s.serverAddr;
      
      # Authentication configuration
      tokenFile = lib.mkIf (config.myconfig.k3s.tokenFile != null) config.myconfig.k3s.tokenFile;
      token = lib.mkIf (config.myconfig.k3s.token != null) config.myconfig.k3s.token;
      
      extraFlags = toString [
        "--write-kubeconfig-mode 600"
        "--flannel-backend=vxlan"
      ];
    };
    
    # Ensure at least one authentication method is provided
    assertions = lib.mkIf (!config.myconfig.features.k3sServer.enable) [
      {
        assertion = (config.myconfig.k3s.tokenFile != null) || (config.myconfig.k3s.token != null);
        message = "k3s agent requires either tokenFile or token to be set for cluster authentication";
      }
    ];

    systemd.services.k3s = lib.mkIf (!config.myconfig.features.k3sServer.enable) {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    environment.variables = lib.mkIf (!config.myconfig.features.k3sServer.enable) {
      KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    };
  };
}