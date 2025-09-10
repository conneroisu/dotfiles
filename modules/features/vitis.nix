{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.vitis";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      # Enable virtualization
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
          ovmf = {
            enable = true;
            packages = [pkgs.OVMFFull.fd];
          };
        };
      };
      networking.firewall.trustedInterfaces = ["virbr0"];

      # Add your user to libvirtd group
      users.users."${myconfig.constants.username}" = {
        extraGroups = ["libvirtd"];
      };

      # Install virt-manager and tools
      environment.systemPackages = with pkgs; [
        virt-manager
        virt-viewer
        spice
        spice-gtk
        spice-protocol
        win-virtio
        win-spice
      ];

      # Enable dconf for virt-manager settings
      programs.dconf.enable = true;

      # Optional: Enable nested virtualization
      boot.kernelModules = ["kvm-intel" "kvm-amd"];
      boot.extraModprobeConfig = ''
        options kvm_intel nested=1
        options kvm_amd nested=1
      '';
    };

    darwin.ifEnabled = {
    };
  }
