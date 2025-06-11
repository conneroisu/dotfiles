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

    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          "@wheel"
          "connerohnesorge"
        ];
        allowed-users = [
          "root"
          "@wheel"
          "connerohnesorge"
        ];
      };
    };
  };
}
