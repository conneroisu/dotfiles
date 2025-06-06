{
  delib,
  inputs,
  pkgs,
  config,
  ...
}: let
  system = "aarch64-darwin";
in
  delib.host {
    name = "Conners-MacBook-Air";
    rice = "dark";
    type = "laptop";

    home.home.stateVersion = "24.11";
    homeManagerSystem = system;

    myconfig = {
      features = {
        engineer.enable = true;
      };
      programs = {
        catls.enable = true;
        convert_img.enable = true;
      };
    };

    nixos = {
      imports = [
        inputs.determinate.nixosModules.default
      ];
      nixpkgs.hostPlatform = "aarch64-linux";
      nixpkgs.config.allowUnfree = true;
      myconfig.features.engineer.enable = pkgs.lib.mkForce false;
      system.stateVersion = "24.11";
      virtualisation.vmware.guest.enable = true;
      boot = {
        loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };
        initrd.availableKernelModules = [
          "ata_piix"
          "mptspi"
          "uhci_hcd"
          "ehci_pci"
          "sd_mod"
          "sr_mod"
        ];
        kernelModules = ["vmw_vsock_vmci_transport" "vmw_balloon" "vmw_vmci" "vmw_pvscsi"];
      };
      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };
        "/boot" = {
          device = "/dev/disk/by-label/boot";
          fsType = "vfat";
          options = ["fmask=0077" "dmask=0077"];
        };
        "/mnt/hgfs" = {
          device = ".host:/";
          fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
          options = [
            "umask=022"
            "uid=1000"
            "gid=1000"
            "allow_other"
            "auto_unmount"
            "defaults"
          ];
        };
      };
      networking = {
        hostName = "mac-nix-vm";
        networkmanager.enable = true;
        useDHCP = pkgs.lib.mkForce true;
        interfaces.ens33.useDHCP = true; # VMware default network interface
      };
      users.users.connerohnesorge = {
        home = "/home/connerohnesorge";
      };
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = true;
        };
      };
      environment.systemPackages = with pkgs; [
        vim
        git
        wget
        curl
        htop
      ];
      programs.zsh.enable = true;
    };

    darwin = {
      imports = [
        inputs.determinate.darwinModules.default
      ];
      nixpkgs = {
        hostPlatform = system;
        config.allowUnfree = true;
      };
      nix.enable = false;
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs;
        [
          # Macos Only
          aerospace
          raycast
          xcodes
          # Shared
        ]
        ++ (with inputs; [
          blink.packages."${system}".default
          blink.packages."${system}".blink-fuzzy-lib
        ]);
      programs = {
        direnv.enable = true;
        direnv.nix-direnv.enable = true;
        ssh = {
          extraConfig = ''
            SetEnv TERM=xterm-256color
          '';
        };
      };
      system = {
        stateVersion = 5;
        defaults = {
          dock.autohide = true;

          trackpad = {
            Clicking = true;
            TrackpadThreeFingerDrag = true;
            Dragging = true;
          };
        };
      };

      environment.shells = [pkgs.zsh];
      users.users.connerohnesorge = {
        home = "/Users/connerohnesorge";
      };

      security.pam.services.sudo_local.touchIdAuth = true;
      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
          # Set up applications.
          echo "setting up /Applications..." >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
          while read -r src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';
    };
  }
