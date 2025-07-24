{ pkgs, ... }: {
  # Editor packages and language servers
  nixos = with pkgs; [
    # Main editor
    neovim
    
    # Language support
    tree-sitter
    vscode-langservers-extracted
    yaml-language-server
  ];
  
  darwin = with pkgs; [
    # Main editor
    neovim
    zed-editor
    
    # Language support
    tree-sitter
    vscode-langservers-extracted
  ];
  
  common = with pkgs; [
    # Common editor tools available on both platforms
  ];
}