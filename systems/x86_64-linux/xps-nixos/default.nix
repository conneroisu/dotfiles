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
  target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  format, # A normalized name for the system target (eg. `iso`).
  virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems, # An attribute map of your defined hosts.
  config,
  ...
}: let
  unstable-pkgs = import inputs.nixpkgs-unstable {
    inherit system;
    config = {
    };
  };
in {
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
    blacklistedKernelModules = [
      "nvidia"
      "nvidia_uvm"
      "nvidia_drm"
      "nvidia_modeset"
    ];
  };

  networking = {
    hostName = "xps-nixos";
    networkmanager.enable = true;
    defaultGateway = {
      # address = "192.168.1.1";
      # interface = "wlp0s20f3";
      address = "192.168.1.19";
      interface = "enp0s13f0u3u1c2";
    };
  };

  systemd.network = {
    enable = true;
    networks."40-enp0s13f0u3u1c2" = {
      matchConfig.Name = "enp0s13f0u3u1c2";
      networkConfig = {
        DHCP = "ipv4";
      };
    };
  };

  time.timeZone = "America/Chicago";

  virtualisation.docker.enable = true;

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

  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        mesa
        mesa.drivers
      ];
    };
    nvidia = {
      modesetting.enable = true;
      open = true;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Name = "Hello";
          ControllerMode = "dual";
          FastConnectable = "true";
          Experimental = "true";
        };
        Policy = {
          AutoEnable = "true";
        };
      };
    };
  };

  services = {
    xserver = {
      enable = true;
      videoDrivers = ["nvidia"];
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    printing.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    libinput.enable = true;
    hypridle.enable = true;
    tlp.enable = true;
    power-profiles-daemon.enable = false;
    ollama.enable = true;
  };

  security.rtkit.enable = true;

  users.users.connerohnesorge = {
    isNormalUser = true;
    description = "Conner Ohnesorge";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = with pkgs; [
      thunderbird
    ];
  };

  programs = {
    steam.enable = true;
    zsh.enable = true;
    hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };
    hyprlock.enable = true;
  };

  environment.systemPackages = with pkgs; [
    nix-ld
    alejandra
    nh
    google-chrome
    unstable-pkgs.hyprland
    hyprcursor
    hyprkeys
    hyprpaper
    hypridle
    hyprsunset
    hyprwayland-scanner
    hyprutils
    hyprnotify
    inputs.hyprwm-qtutils.packages.${system}.hyprland-qtutils
    waybar
    xdg-desktop-portal-hyprland
    uwsm
    networkmanager_dmenu
    tlp
    dunst
    pipewire
    grimblast
    grim
    slurp
    rofi
    rofi-rbw
    rofi-obsidian
    rofi-bluetooth
    rofi-power-menu
    spotify
    android-studio
    gpu-screen-recorder
    brightnessctl
    wl-clipboard
    gtk3
    gtk-layer-shell
    usbutils
    vmware-horizon-client
    sox
    alsa-utils
    alsa-lib
    alsa-oss
    docker
    docker-compose
    docker-compose-language-service
    quartus-prime-lite
    ghdl
    nvc
    lshw
    pkgconf
    nvidia-docker
    nvtopPackages.nvidia
    gdb
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
