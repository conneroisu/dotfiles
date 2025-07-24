{ pkgs, ... }: {
  # Core CLI utilities and shell tools
  nixos = with pkgs; [
    # File operations
    bat
    fd
    fdtools
    tree
    eza
    stow
    age
    file
    unzip
    lsof
    
    # Text processing
    jq
    yq
    sad
    ripgrep
    tealdeer
    unixtools.xxd
    
    # Shell environment
    fzf
    zsh
    nushell
    carapace
    starship
    direnv
    nix-direnv
    atuin
    zoxide
    zinit
    
    # System monitoring
    htop
    procps
    lshw
    upower
    upower-notify
    
    # Terminal utilities
    zellij
    tmux
    delta
    sleek
    
    # System utilities
    dbus
    usbutils
    ethtool
    ffmpeg
  ];
  
  darwin = with pkgs; [
    # File operations
    bat
    fd
    tree
    eza
    stow
    unzip
    
    # Text processing
    jq
    yq
    sad
    ripgrep
    tealdeer
    unixtools.xxd
    
    # Shell environment
    fzf
    carapace
    starship
    direnv
    nix-direnv
    atuin
    zoxide
    zinit
    
    # System monitoring
    htop
    
    # Terminal utilities
    zellij
    delta
    sleek
  ];
  
  common = with pkgs; [
    # Common utilities available on both platforms
  ];
}