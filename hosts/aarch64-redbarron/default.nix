{
  pkgs,
  unstable-pkgs,
  config,
  ghostty,
  ...
}: {
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
  };

  time.timeZone = "America/Chicago";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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
    google-chrome
    ghostty.packages."${system}".default
    waybar
    pipewire
    brightnessctl
    wl-clipboard
    gtk3
    gtk-layer-shell
    usbutils
    sox
    alsa-utils
    alsa-lib
    alsa-oss
    ghdl
    lshw
    pkgconf
  ];

  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyodark.yaml";
    image = "";
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
