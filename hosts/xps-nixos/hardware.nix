{
  delib,
  lib,
  modulesPath,
  config,
  inputs,
  ...
}:
delib.host {
  name = "xps-nixos";

  homeManagerSystem = "x86_64-linux";
  home.home.stateVersion = "24.11";

  nixos = {
    nixpkgs.hostPlatform = "x86_64-linux";
    system.stateVersion = "24.11";

    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
      inputs.nixos-hardware.nixosModules.dell-xps-15-9510
    ];

    virtualisation.docker.enable = true;
    hardware.nvidia-container-toolkit.enable = true;
    boot = {
      initrd.availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "uas"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      initrd.kernelModules = [];
      kernelModules = ["kvm-intel"];
      extraModulePackages = [];
    };

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/fd77e04d-21ab-4b5d-a2b0-14d54f734848";
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/DBE6-A378";
        fsType = "vfat";
        options = ["fmask=0077" "dmask=0077"];
      };
      "/mnt/media" = {
        device = "/dev/disk/by-uuid/ce3b09bd-96b8-481d-9b0f-b1e18e08cd51";
        fsType = "ext4";
        options = ["defaults" "nofail" "x-gvfs-show"];
      };
    };
    swapDevices = [];

    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    networking = {
      hostName = "xps-nixos";
      networkmanager.enable = true;
      useDHCP = lib.mkDefault true;
      # interfaces.enp0s13f0u3u1c2 = {
      #   useDHCP = true; # If you want to use DHCP
      #   # Or for static IP:
      #   # ipv4.addresses = [ {
      #   #   address = "192.168.1.2";
      #   #   prefixLength = 24;
      #   # } ];
      # };
    };

    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
