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
      serverAddr = "https://127.0.0.1:6443";
      extraFlags = toString [
        "--write-kubeconfig-mode 644"
        "--flannel-backend=vxlan"
      ];
    };

    systemd.services.k3s = lib.mkIf (!config.myconfig.features.k3sServer.enable) {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    environment.variables = lib.mkIf (!config.myconfig.features.k3sServer.enable) {
      KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    };
  };
}