{ pkgs, ... }: {
  # Network tools and utilities
  nixos = with pkgs; [
    # Network utilities
    curl
    wget
    dnsutils
    tailscale
    
    # Communication tools
    minicom
    openvpn
    
    # Network analysis
    arp-scan
    ethtool
    
    # Browser integration
    vdhcoapp
  ];
  
  darwin = with pkgs; [
    # Network utilities
    wget
  ];
  
  common = with pkgs; [
    # Common networking tools available on both platforms
  ];
}