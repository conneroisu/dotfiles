# Wrapper module to adapt denix configurations for nixos-generators
{ config, lib, pkgs, modulesPath, inputs ? {}, ... }:

{
  # Basic system configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.useDHCP = lib.mkDefault true;
  networking.hostName = lib.mkDefault "nixos-generated";

  # User configuration from constants
  users.users.connerohnesorge = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "nixos"; # Change this after first boot!
    home = "/home/connerohnesorge";
  };

  # Basic services
  services.openssh.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Basic development tools (similar to engineer feature)
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
    tmux
    tree
    unzip
    zip
  ];

  # Enable basic programs
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Nix configuration
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" "connerohnesorge" ];
    allowed-users = [ "root" "@wheel" "connerohnesorge" ];
  };

  system.stateVersion = "24.11";
}