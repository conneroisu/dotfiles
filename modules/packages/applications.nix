{ pkgs, ... }: {
  # GUI applications and desktop tools
  nixos = with pkgs; [
    # Productivity
    obsidian
    zathura
    
    # Web browsers
    brave
    
    # Media
    spotify
    obs-studio
    eog
    
    # Communication
    discord
    telegram-desktop
    
    # File managers
    nemo-with-extensions
  ];
  
  darwin = with pkgs; [
    # No GUI applications specified for darwin in original config
  ];
  
  common = with pkgs; [
    # Common applications available on both platforms
  ];
}