{
  config,
  modulesPath,
  system,
  pkgs,
  unstable-pkgs,
  inputs,
  ...
}:

let
  sharedPkgs = (import ../Shared { inherit pkgs unstable-pkgs; }).environment.systemPackages;
in
{
  imports = [
  	"${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.wireless.enable = false;

  time.timeZone = "America/Chicago";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      open = true;
    };
    bluetooth = {
      enable = true;
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
      videoDrivers = [ "nvidia" ];
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
  };
  security.rtkit.enable = true;

  users.users.connerohnesorge = {
    isNormalUser = true;
    description = "Conner Ohnesorge";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      #  thunderbird
    ];
  };

  programs = {
    zsh.enable = true;
    hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };
  };

  environment.systemPackages =
    sharedPkgs
    ++ (with pkgs; [
      nix-ld
      alejandra
      nh
      pkgs.home-manager
      firefox
      wget
      git
      neovim
      hyprland
      hyprcursor
      hyprkeys
      hyprpaper
      hyprsunset
      hyprwayland-scanner
      hyprutils
      xdg-desktop-portal-hyprland
      uwsm
      tlp
      dunst
      pipewire
      grimblast
      grim
      slurp
      rofi
      gh
      matugen
      brightnessctl
      pfetch-rs
      xfce.thunar
      wl-clipboard
      kitty
      gtk3
      gtk-layer-shell
      sox
      alsa-utils
      alsa-lib
      alsa-oss
      docker
      docker-compose
      docker-compose-language-service
      ghdl
      nvc
      lshw
      htop
      pkgconf
      verible
      nvidia-docker
      nvtopPackages.nvidia

      gdb
      pkg-config
    ]);

  # Leave this.
  system.stateVersion = "24.11";
}
