{
  delib,
  lib,
  modulesPath,
  config,
  ...
}:
delib.host {
  name = "hwsl-nixos";

  homeManagerSystem = "x86_64-linux";
  home.home.stateVersion = "24.11";

  nixos = {
    nixpkgs.hostPlatform = "x86_64-linux";
    system.stateVersion = "24.11";

    imports = [
      (modulesPath + "/profiles/minimal.nix")
    ];

    # WSL-specific hardware configuration
    # No physical hardware modules needed for WSL
    boot.initrd.availableKernelModules = [];
    boot.initrd.kernelModules = [];
    boot.kernelModules = [];
    boot.extraModulePackages = [];

    # WSL doesn't use traditional filesystems
    # These will be managed by the WSL module
    fileSystems = {};
    swapDevices = [];

    # No hardware-specific firmware needed in WSL
    hardware.enableRedistributableFirmware = lib.mkDefault false;
  };
}