{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  # config,
  ...
}:
with lib;
with lib.${namespace}; {
  # Your configuration.
  imports = [
    ./hardware.nix
  ];

  snowfallorg.users.connerohnesorge = {
    admin = true;
    create = false;
    home = {
      enable = true;
    };
  };
  # Leave this.
  system.stateVersion = "24.11";

  boot = {
    plymouth.enable = true;
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "xps-nixos";
    networkmanager.enable = true;
    defaultGateway = {
      address = "192.168.1.1";
      interface = "wlp0s20f3";
      # address = "192.168.1.19";
      # interface = "enp0s13f0u3u1c2";
    };
  };

  systemd = {
    targets.network-online.wantedBy = pkgs.lib.mkForce []; # Normally ["multi-user.target"]
    services.NetworkManager-wait-online.wantedBy = pkgs.lib.mkForce []; # Normally ["network-online.target"]
  };

  time.timeZone = "America/Chicago";

  nix.extraOptions = ''
    trusted-users = root connerohnesorge
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

  environment.variables = {
    EXTRA_CCFLAGS = "-I/usr/include";
  };

  ${namespace} = {
    hardware = {
      nvidia.enable = true;
      nvidia-prime.enable = true;
      bluetooth.enable = true;
      audio.enable = true;
      power-efficient.enable = true;
    };
    wm = {
      hyprland.enable = true;
    };
    package-sets = {
      office.enable = true;
    };
  };

  services = {
    # journald.extraConfig = ''
    #   Storage=volatile RateLimitIntervalSec=30s
    #   RateLimitBurst=10000
    #   SystemMaxUse=16M
    #   RuntimeMaxUse=16M
    # '';

    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };

    printing.enable = true;
    libinput.enable = true;

    ollama = {
      enable = true;
      package = pkgs.ollama;
      acceleration = "cuda";
    };
  };

  security.rtkit.enable = true;

  users.users.connerohnesorge = {
    shell = pkgs.nushell;
    isNormalUser = true;
    description = "Conner Ohnesorge";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = with pkgs; [];
  };

  programs = {
    zsh.enable = true;
  };

  environment.systemPackages = with pkgs; [
    nix-ld
    alejandra
    nh
    pipewire
    gpu-screen-recorder
    gtk3
    gtk-layer-shell
    usbutils
    vmware-horizon-client
    yazi
    docker
    docker-compose
    docker-compose-language-service
    vdhcoapp

    beekeeper-studio
    google-chrome

    ghdl
    nvc
    lshw
    pkgconf
    gdb
    gitRepo
    gnupg
    autoconf
    curl
    procps
    gnumake
    util-linux
    unzip
    libGLU
    wgnord
    libGL
    xorg.libXi
    xorg.libXmu
    freeglut
    xorg.libXext
    xorg.libX11
    xorg.libXv
    xorg.libXrandr
    zlib
    stdenv.cc
    binutils
    espeak-ng
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
}
