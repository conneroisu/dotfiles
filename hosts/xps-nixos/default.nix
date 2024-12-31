{
  pkgs,
  unstable-pkgs,
  config,
  ghostty,
  hyprwm-qtutils,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];
  # Leave this.
  system.stateVersion = "24.11";
  sops = {
    defaultSopsFile = ./../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/connerohnesorge/.config/sops/age/keys.txt";
    secrets = {
      "wireguard/public_key".owner = "connerohnesorge";
      "wireguard/private_key".owner = "connerohnesorge";
    };
  };

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
  };

  time.timeZone = "America/Chicago";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
      };
    };
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
    ghostty.packages."${system}".default
    hyprwm-qtutils.packages.${system}.hyprland-qtutils
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
    kitty
    gtk3
    gtk-layer-shell
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
    image = ./../../../Pictures/klaus-desktop.jpeg;
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
