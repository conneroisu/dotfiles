{
  delib,
  inputs,
  pkgs,
  ...
}:
delib.host {
  name = "xps-nixos";

  rice = "dark";
  type = "laptop";
  home.home.stateVersion = "24.11";

  darwin = {
    imports = [
      inputs.determinate.darwinModules.default
    ];
    nixpkgs.hostPlatform = "aarch64-darwin";
    system.stateVersion = "24.11";
  };

  nixos = {
    imports = [
      inputs.determinate.nixosModules.default
      inputs.nixos-hardware.nixosModules.dell-xps-15-9510
    ];

    myconfig = {
      features = {
        nvidia.enable = true;
        power-efficient.enable = true;
        audio.enable = true;
        bluetooth.enable = true;
        hyprland.enable = true;
        engineer.enable = true;
        darknet.enable = true;
        secrets.enable = true;
        student.enable = true;
        intel.enable = true;
      };
      programs = {
        nordvpn.enable = true;
        proton-x.enable = true;
      };
    };

    nixpkgs.config.allowUnfree = true;
    nixpkgs.hostPlatform = "x86_64-linux";
    boot = {
      plymouth.enable = true;
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        systemd-boot.configurationLimit = 4;
      };
    };
    hardware = {
      nvidia = {
        prime = {
          # Bus ID of the Intel GPU.
          intelBusId = "PCI:0:2:0";
          # Bus ID of the NVIDIA GPU.
          nvidiaBusId = "PCI:1:0:0";
        };
      };
    };
    security.rtkit.enable = true;
    services = {
      ## Devices
      printing.enable = true;
      libinput.enable = true;
    };

    time.timeZone = "America/Chicago";
    i18n = {
      # Select internationalisation properties.
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
    };

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
      useDHCP = pkgs.lib.mkDefault true;
      # interfaces.enp0s13f0u3u1c2 = {
      #   useDHCP = true; # If you want to use DHCP
      #   # Or for static IP:
      #   # ipv4.addresses = [ {
      #   #   address = "192.168.1.2";
      #   #   prefixLength = 24;
      #   # } ];
      # };
    };

    system.stateVersion = "24.11";
  };
}
