{ pkgs, ... }: {
  # Container and orchestration tools
  nixos = with pkgs; [
    # Docker
    docker
    docker-compose
    docker-buildx
    lazydocker
    
    # Kubernetes
    kubectl
    ktailctl
  ];
  
  darwin = with pkgs; [
    # Container tools
    podman
    rancher
  ];
  
  common = with pkgs; [
    # Common container tools available on both platforms
  ];
}