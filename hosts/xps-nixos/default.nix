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
    };
    programs = {
      catls.enable = true;
      convert_img.enable = true;
      cmbd.enable = true;
    };
  };

  nixos = {
    imports = [
      inputs.determinate.nixosModules.default
    ];
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

    # environment = {
    #   etc."nix/nix.custom.conf".text = let
    #     # This function converts an attribute set to Nix configuration lines
    #     settingsToConf = settings:
    #       pkgs.lib.concatStringsSep "\n" (
    #         pkgs.lib.mapAttrsToList (
    #           name: value: "${name} = ${
    #             if builtins.isBool value
    #             then pkgs.lib.boolToString value
    #             else if builtins.isInt value
    #             then toString value
    #             else if builtins.isList value
    #             then pkgs.lib.concatMapStringsSep " " (x: "${toString x}") value
    #             else if builtins.isString value
    #             then value
    #             else throw "Unsupported type for nix.conf setting ${name}"
    #           }"
    #         )
    #         settings
    #       );
    #   in
    #     settingsToConf {
    nix = {
      # enable = true;
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
  # };
  # };
}
