{
  delib,
  inputs,
  ...
}:
delib.host {
  name = "xps-nixos";

  rice = "dark";
  type = "laptop";
  home.home.stateVersion = "24.11";

  # This is just here to make the denix host module happy.
  # It evaluates each hosts: darwin, nixos, ... TODO: Improve comment.
  darwin = {
    imports = [
      inputs.determinate.darwinModules.default
    ];
    nixpkgs.hostPlatform = "x86_64-darwin";
    system.stateVersion = "24.11";
  };

  nixos = {
    imports = [
      inputs.determinate.nixosModules.default
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
        ollama.enable = true;
      };
      programs = {
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

    networking = {
      hostName = "xps-nixos";
      networkmanager.enable = true;
      defaultGateway = {
        #   # address = "192.168.1.1";
        #   # interface = "wlp0s20f3";
        address = "192.168.1.19";
        #   # interface = "enp0s13f0u3u1c2";
        interface = "enp0s13f0u4c2";
      };
    };

    hardware = {
      enableAllFirmware = true;
      nvidia = {
        prime = {
          # Bus ID of the Intel GPU.
          intelBusId = "PCI:0:2:0";
          # Bus ID of the NVIDIA GPU.
          nvidiaBusId = "PCI:1:0:0";
        };
      };
    };
    security = {
      rtkit.enable = true;
      pam.services.login.enableGnomeKeyring = true;
    };
    services = {
      ## Devices
      printing.enable = true;
      libinput.enable = true;
      gnome.gnome-keyring.enable = true;
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
  };
}
