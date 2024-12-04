# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  time.timeZone = "America/Chicago";

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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
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
  services.libinput.enable = true;
  
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
    };
  };
  
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.connerohnesorge = {
    isNormalUser = true;
    description = "Conner Ohnesorge";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      hyprland
    ];
  };
  environment.variables.EDITOR = "nvim";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    pkgs.home-manager
    git
    xz
    unzip
    gnumake
    cmake

    # CLIs
    turso-cli
    flyctl
    gh
    nh

    neovim
    kitty
    zsh
    ripgrep
    fzf
    fd
    bat
    nix-index
    nix-prefetch-git
    jq
    delta
    tree
    fd

    # Window Manager
    hyprland
    hyprutils
    dunst
    hyprcursor
    hyprlock
    hyprkeys
    hyprpaper
    uwsm
    hyprwayland-scanner
    pipewire
    grimblast
    rofi
    gpu-screen-recorder
    matugen
    brightnessctl
    pfetch-rs
    aquamarine
    xfce.thunar
    wl-clipboard
    kitty

    nix-ld
    nixfmt-rfc-style
    lexical
    tealdeer
    sox

    vim
    neovim
    zsh
    zinit
    jq
    bat
    fzf
    gh
    gum
    kitty

    # Sound
    alsa-utils
    alsa-lib
    alsa-oss

    docker
    docker-compose
    docker-compose-language-service

    zellij
    atuin
    zoxide
    nixos-generators
    emacs

    fd
    delta
    sad
    tailwindcss
    starship
    gcc
    llvm
    rustup
    obsidian
    vhdl-ls
    nodejs
    typescript
    stow
    nil
    nvc
    ruby
    zig
    elixir
    ocaml
    ocamlPackages.ocaml-lsp
    dune_3
    python312
    python312Packages.numpy
    python312Packages.pandas
    python312Packages.scipy
    python312Packages.matplotlib
    python312Packages.scikitlearn
    python312Packages.torch
    python312Packages.opencv4
    python312Packages.torchvision
    python312Packages.selenium
    python312Packages.pyarrow
    python312Packages.psycopg
    python312Packages.mysqlclient
    python312Packages.ollama
    python312Packages.black
    python312Packages.requests
    python312Packages.uvicorn
    python312Packages.flask
    python312Packages.fastapi
    python312Packages.django
    python312Packages.gunicorn
    python312Packages.pydantic
    python312Packages.mypy
    python312Packages.torchdiffeq
    python312Packages.beautifulsoup4
    python312Packages.pillow
    python312Packages.gym
    python312Packages.pypdf
    python312Packages.pytest
    ripgrep
    vscode

    golangci-lint
    go
    revive
    templ
    iferr
    golines
    gomodifytags
    sqls
    sqlite
    sqlite-vec
    # Language Servers
    lua-language-server
    htmx-lsp
    texlab
    ltex-ls
    shellcheck
    jdt-language-server
    zls
    jq-lsp
    luajitPackages.luarocks
    wget
    meson
    # python312Packages.basedpyright # TODO: add to nixpkgs

    # Formatters
    hclfmt
    nixfmt-rfc-style
    cbfmt

    # Libraries
    glslang
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  system.stateVersion = "24.11"; # Did you read the comment?

}
