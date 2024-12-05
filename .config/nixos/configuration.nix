{
  config,
  pkgs,
  unstable-pkgs,
  inputs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot = {
    plymouth.enable = true;
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    blacklistedKernelModules = ["nvidia" "nvidia_uvm" "nvidia_drm" "nvidia_modeset"];
  };

  networking.hostName = "nixos"; # Define your hostname.
  nixpkgs.config.allowUnfree = true;
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

  virtualisation.docker.enable = true;
  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        mesa
        mesa.drivers
      ];
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true;
        };
      };
    };
    nvidia = {
      modesetting.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      open = true;
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

    # Enable CUPS to print documents.
    printing.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
  security.rtkit.enable = true;

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

  programs = {
    zsh.enable = true;
    hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    pkgs.home-manager
    google-chrome
    inputs.zen-browser.packages."${system}".default
    wget
    git
    gnumake
    cmake
    go-task
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
    swappy

    nerdfonts
    unzip
    turso-cli
    spotify
    flyctl
    gh
    nh
    gcc
    zig
    llvm
    kitty
    zsh
    ripgrep
    fzf
    fd
    nix-index
    nix-prefetch-git
    jq
    yq
    delta
    tree
    dunst
    pipewire
    grimblast
    grim
    slurp
    uv
    rofi
    gpu-screen-recorder
    matugen
    brightnessctl
    pfetch-rs
    xfce.thunar
    wl-clipboard
    kitty
    gtk3
    gtk-layer-shell
    gobject-introspection

    nix-ld
    alejandra
    vmware-horizon-client
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
    quartus-prime-lite
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
    lshw
    sad
    shfmt
    nvidia-docker
    nvtopPackages.nvidia

    elixir
    ocaml
    go
    goreleaser

    dune_3
    basedpyright

    pkg-config
    python312
    (python312.withPackages (
      ps:
        with ps; [
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
          pytest
          pip
        ]
    ))

    # LSP
    lua-language-server
    nixd
    statix
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
    actionlint
    verible
    revive
    golangci-lint-langserver
    golangci-lint
    templ
    gomodifytags
    gotests
    impl
    unstable-pkgs.iferr
  ];

  # Leave this.
  system.stateVersion = "24.11";
}
