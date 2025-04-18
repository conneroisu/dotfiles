{
  lib,
  pkgs,
  inputs,
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  config,
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
  sops = {
    defaultSopsFile = ./../../../.secrets/secrets.yaml;
    age.keyFile = "/home/connerohnesorge/.config/sops/age/keys.txt";
    secrets = {
      nord_username.mode = "0440";
      nord_password.mode = "0440";
      nord_username.owner = "connerohnesorge";
      nord_password.owner = "connerohnesorge";
    };
    templates = {
      "nord-credentials" = {
        content = ''
          "${config.sops.placeholder.nord_username}"
          "${config.sops.placeholder.nord_password}"
        '';
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };
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
      systemd-boot.configurationLimit = 4;
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

  programs.ssh.askPassword = lib.mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";

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
    openvpn = {
      servers = {
        us9662 = {
          autoStart = true;
          updateResolvConf = true;
          config = ''
            client
            dev tun
            proto tcp
            remote 181.214.151.194 443
            resolv-retry infinite
            remote-random
            nobind
            tun-mtu 1500
            tun-mtu-extra 32
            mssfix 1450
            persist-key
            persist-tun
            ping 15
            ping-restart 0
            ping-timer-rem
            reneg-sec 0
            comp-lzo no
            verify-x509-name CN=us9662.nordvpn.com
            remote-cert-tls server

            auth-user-pass ${config.sops.templates."nord-credentials".path}

            verb 3
            pull
            fast-io
            cipher AES-256-CBC
            auth SHA512
            redirect-gateway def1

            dhcp-option DNS 103.86.96.100
            dhcp-option DNS 103.86.99.100
            <ca>
            -----BEGIN CERTIFICATE-----
            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
            -----END CERTIFICATE-----
            </ca>
            key-direction 1
            <tls-auth>
            #
            # 2048 bit OpenVPN static key
            #
            -----BEGIN OpenVPN Static key V1-----
            e685bdaf659a25a200e2b9e39e51ff03
            0fc72cf1ce07232bd8b2be5e6c670143
            f51e937e670eee09d4f2ea5a6e4e6996
            5db852c275351b86fc4ca892d78ae002
            d6f70d029bd79c4d1c26cf14e9588033
            cf639f8a74809f29f72b9d58f9b8f5fe
            fc7938eade40e9fed6cb92184abb2cc1
            0eb1a296df243b251df0643d53724cdb
            5a92a1d6cb817804c4a9319b57d53be5
            80815bcfcb2df55018cc83fc43bc7ff8
            2d51f9b88364776ee9d12fc85cc7ea5b
            9741c4f598c485316db066d52db4540e
            212e1518a9bd4828219e24b20d88f598
            a196c9de96012090e333519ae18d3509
            9427e7b372d348d352dc4c85e18cd4b9
            3f8a56ddb2e64eb67adfc9b337157ff4
            -----END OpenVPN Static key V1-----
            </tls-auth>
          '';
        };
      };
    };

    # journald.extraConfig = ''
    #   Storage=volatile RateLimitIntervalSec=30s
    #   RateLimitBurst=10000
    #   SystemMaxUse=16M
    #   RuntimeMaxUse=16M
    # '';

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
    ];
    packages = with pkgs; [];
  };

  programs = {
    zsh.enable = true;
  };

  environment.systemPackages =
    (with inputs; [
      ])
    ++ (with pkgs."${namespace}"; [
      httptap
    ])
    ++ (with pkgs; [
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

      # Networking
      openvpn
      cacert
      arp-scan
      vdhcoapp
      obs-studio
      davinci-resolve

      # Hardware
      usbutils

      # Emulation
      qemu
      docker
      dockerfile-language-server-nodejs
      docker-compose
      docker-compose-language-service

      # Apps
      netron
      pkgs.xfce.thunar
      vmware-horizon-client
      gimp
      pkgs.jetbrains.rust-rover
      pkgs.libnotify
      anki
      teams-for-linux

      ghdl
      nvc
      lshw
      pkgconf
      gdb
      gnupg
      autoconf
      curl
      procps
      gnumake
      util-linux
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
      zlib
      stdenv.cc
      binutils
      espeak-ng
      llama-cpp
    ]);

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
