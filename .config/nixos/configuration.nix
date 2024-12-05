# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  nixpkgs.config.allowUnfree = true;
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
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

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
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

  # Install firefox.
  programs = {
    firefox.enable = true;
    zsh.enable = true;
    hyprland = {
      enable = true;
      withUWSM = true;
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    pkgs.home-manager
    wget
    git
    gnumake
    cmake
    neovim
    hyprland
    unzip
    turso-cli
    flyctl
    gh
    google-chrome
    nh
    gcc
    zig
    llvm
    kitty
    zsh
    ripgrep
    fzf
    fd
    bat
    nix-index
    nix-prefetch-git
    jq
    yq
    delta
    tree
    fd
    hyprutils
    dunst
    hyprcursor
    hyprkeys
    hyprpaper
    uwsm
    hyprwayland-scanner
    wlsunset
    pipewire
    grimblast
    grim
    xdg-desktop-portal-hyprland
    uv
    rofi
    gpu-screen-recorder
    matugen
    brightnessctl
    pfetch-rs
    aquamarine
    xfce.thunar
    wl-clipboard
    kitty
    gtk3
    gtk-layer-shell
    gobject-introspection

    nix-ld
    vmware-horizon-client
    nixfmt-rfc-style
    tealdeer
    sox
    zinit
    bat
    zellij
    gum
    alsa-utils
    alsa-lib
    alsa-oss
    docker
    docker-compose
    docker-compose-language-service
    ollama
    tailwindcss
    rustup
    gcc
    starship
    nodejs
    obsidian
    stow
    ghdl
    emacs
    nvc
    atuin
    pkgconf
    delve
    zoxide
    sad
    shfmt

    elixir
    ocaml
    dune_3
    basedpyright

    python312
    pkg-config
    (python312.withPackages (
      ps: with ps; [
        numpy
        pandas
        scipy
        matplotlib
        scikitlearn
        torch
        opencv4
        torchvision
        selenium
        pyarrow
        psycopg
        mysqlclient
        ollama
        black
        requests
        uvicorn
        flask
        fastapi
        django
        gunicorn
        pydantic
        mypy
        torchdiffeq
        beautifulsoup4
        pillow
        gym
        pypdf
        click
        pytest
        cairo
        pycairo
        loguru
        pygobject3
        pygobject-stubs
        pip
      ]
    ))

    # LSP
    lua-language-server
    nil
    ocamlPackages.ocaml-lsp
    shellcheck
    vhdl-ls
    ltex-ls
    hyprls
    zls
    sqls
    yaml-language-server
    svelte-language-server
    matlab-language-server
    cmake-language-server
    astro-language-server
    jdt-language-server
    lexical
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
