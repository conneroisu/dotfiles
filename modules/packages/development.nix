{ pkgs, ... }: {
  # Development tools and build systems
  nixos = with pkgs; [
    # Version control
    git
    git-lfs
    jujutsu
    
    # Platform tools
    gh
    tea
    doppler
    fh
    
    # Build tools
    gcc
    cmake
    gnumake
    pkg-config
    gdb
    
    # Security
    gnupg
    cacert
    
    # Nix tools
    nix-index
    nixos-shell
    statix
    
    # Utilities
    openssl
  ];
  
  darwin = with pkgs; [
    # Version control
    git
    
    # Platform tools
    gh
    tea
    fh
    flyctl
    
    # Build tools
    cmake
    gnumake
    openssl
    
    # Graphics/UI tools
    graphite-cli
    spicetify-cli
  ];
  
  common = with pkgs; [
    # Common development tools
  ];
}