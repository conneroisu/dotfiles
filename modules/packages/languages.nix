{ pkgs, ... }: {
  # Programming languages and runtimes
  nixos = with pkgs; [
    # Nix
    nixd
    
    # JavaScript/TypeScript
    nodejs
    bun
    
    # Python
    uv
    
    # Lua
    lua-language-server
    
    # Disk utilities
    squirreldisk
  ];
  
  darwin = with pkgs; [
    # Nix
    nixd
    
    # JavaScript/TypeScript
    nodejs
    bun
    
    # Python
    uv
    python313Packages.huggingface-hub
    
    # Lua
    lua-language-server
  ];
  
  common = with pkgs; [
    # Common language tools available on both platforms
  ];
}