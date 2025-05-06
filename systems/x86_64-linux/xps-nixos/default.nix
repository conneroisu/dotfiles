{
  lib,
  pkgs,
  namespace,
  # inputs,
  ...
}:
with lib;
with lib.${namespace}; {
  imports = [
    ./hardware.nix
  ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["root" "connerohnesorge" "@wheel"];
    allowed-users = ["root" "connerohnesorge" "@wheel"];

    substituters = [
      "https://cache.nixos.org"
      "https://conneroisu.cachix.org"
      "https://pegwings.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "conneroisu.cachix.org-1:PgOlJ8/5i/XBz2HhKZIYBSxNiyzalr1B/63T74lRcU0="
      "pegwings.cachix.org-1:FYxyFKhWG20aISJjFgWMuohJj3iLNW2hVAS4u48Be00="
    ];
  };

  home-manager.backupFileExtension = "bak";

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
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      systemd-boot.configurationLimit = 3;
    };
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
    # Create a separate slice for nix-daemon that is
    # memory-managed by the userspace systemd-oomd killer
    slices."nix-daemon".sliceConfig = {
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "50%";
    };

    services = {
      "nix-daemon".serviceConfig.Slice = "nix-daemon.slice";
      # If a kernel-level OOM event does occur anyway,
      # strongly prefer killing nix-daemon child processes
      "nix-daemon".serviceConfig.OOMScoreAdjust = 1000;
      NetworkManager-wait-online.wantedBy = pkgs.lib.mkForce []; # Normally ["network-online.target"]
    };
    targets.network-online.wantedBy = pkgs.lib.mkForce []; # Normally ["multi-user.target"]
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

  programs = {
    _1password = {
      enable = true;
    };
    _1password-gui = {
      enable = true;

      polkitPolicyOwners = ["connerohnesorge"];
    };

    _1password-shell-plugins = {
      # enable 1Password shell plugins for bash, zsh, and fish shell
      enable = true;
      # the specified packages as well as 1Password CLI will be
      # automatically installed and configured to use shell plugins
      plugins = with pkgs; [gh];
    };
    ssh = {
      askPassword = lib.mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
    };
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
    tailscale.enable = true;
    xserver = {
      enable = true;
      displayManager = {
        gdm.enable = true;
        # sddm.enable = true;
      };
      desktopManager = {
        gnome.enable = true;
        xfce.enable = true;
      };
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
    # shell = pkgs.nushell;
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "Conner Ohnesorge";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "users"
    ];
    packages = [];
  };

  programs = {
    zsh.enable = true;
  };

  environment = {
    etc."nix/nix.custom.conf".text = let
      # This function converts an attribute set to Nix configuration lines
      settingsToConf = settings:
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            name: value: "${name} = ${
              if builtins.isBool value
              then lib.boolToString value
              else if builtins.isInt value
              then toString value
              else if builtins.isList value
              then lib.concatMapStringsSep " " (x: "${toString x}") value
              else if builtins.isString value
              then value
              else throw "Unsupported type for nix.conf setting ${name}"
            }"
          )
          settings
        );
    in
      # Apply the function to your desired settings
      settingsToConf {
        # Add your nix settings here, for example:
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
    systemPackages = with pkgs; [
      gitRepo
      nix-ld
      alejandra
      nh
      pipewire
      gtk3
      glibc.dev
      gtk-layer-shell
      yazi

      busybox
      util-linux
      binutils

      # Communication
      openvpn
      cacert
      arp-scan
      vdhcoapp
      usbutils

      # Emulation
      docker
      docker-compose

      # Apps
      xfce.thunar

      lshw
      gdb
      gnupg
      curl
      procps
      unzip
      libGLU
      libGL
      freeglut
      xorg.libXi
      xorg.libXmu
      xorg.libXext
      xorg.libX11
      xorg.libXv
      xorg.libXrandr
    ];
  };

  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyodark.yaml";
    image = ./../../../assets/klaus-desktop.jpeg;
    polarity = "dark";
    cursor = {
      size = 12;
      name = "rose-pine-hyprcursor";
      package = pkgs.rose-pine-hyprcursor;
    };
    targets = {
      grub.enable = false;
      qt.enable = true;
      plymouth.enable = false;
      gnome.enable = true;
      gtk.enable = true;
      spicetify.enable = true;
    };
  };
}
