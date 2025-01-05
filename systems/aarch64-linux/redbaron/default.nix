{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  format, # A normalized name for the system target (eg. `iso`).
  virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems, # An attribute map of your defined hosts.
  # All other arguments come from the system system.
  config,
  modulesPath,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Leave this.
  system.stateVersion = "24.11";

  boot = {
    plymouth.enable = false;
    loader.grub.enable = false;
    loader.generic-extlinux-compatible.enable = true;
  };

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFmAertOR3AYYKKvgGcaKFlqrKuGiWX4BEkgQp5/t+4+"
  ];

  time.timeZone = "America/Chicago";

  nix.extraOptions = ''
    trusted-users = root connerohnesorge pilot
  '';

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

  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        mesa
        mesa.drivers
      ];
    };
    bluetooth = {
      enable = false;
    };
  };

  services = {
    printing.enable = false;
    power-profiles-daemon.enable = false;
    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    libinput.enable = true;
  };

  security.rtkit.enable = true;

  snowfallorg.users.root = {
    password = "connerohnesorge";
  };
  users.users.connerohnesorge = {
    isNormalUser = true;
    description = "Conner Ohnesorge";
    extraGroups = [
      "wheel"
    ];
    packages = [
    ];
  };

  programs = {
    zsh.enable = true;
  };

  environment.systemPackages = with pkgs; [
    nix-ld
    alejandra
    nh
    gh
    pipewire
    brightnessctl
    gtk3
    gtk-layer-shell
    usbutils
    sox
    alsa-utils
    alsa-lib
    alsa-oss
    lshw
    pkgconf
    emulationstation
    curl
    wget
    gh
  ];

  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyodark.yaml";
    image = ./../../../assets/klaus-desktop.jpeg;
    polarity = "dark";
    targets = {
      grub.enable = false;
      plymouth.enable = false;
      gnome.enable = true;
      gtk.enable = true;
      spicetify.enable = true;
    };
  };

  disko.devices = {
    disk = {
      my-disk = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
