{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib; let
  cfg = config.${namespace}.hardware.nvidia-prime;
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in {
  options.${namespace}.hardware.nvidia-prime = with types; {
    enable = mkEnableOption "Nvidia support";
    driverType = mkOption {
      type = types.enum [
        "stable"
        "beta"
        "production"
        "vulkan_beta"
        "legacy_470"
        "legacy_390"
        "legacy_340"
        "custom"
      ];
      default = "stable";
      description = "Type of NVIDIA driver to use. Use 'custom' to specify a custom driver package.";
    };

    customDriverPackage = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "Custom NVIDIA driver package. This option is used when 'driverType' is set to 'custom'.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nvidia-offload
      pciutils
      cudaPackages.cudnn
      cudaPackages.cuda_nvcc
    ];

    # Enable OpenGL
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    boot = {
      blacklistedKernelModules = [
        "nouveau"
        "nvidia"
        "nvidia_uvm"
        "nvidia_drm"
        "nvidia_modeset"
      ];
      initrd.kernelModules = ["nvidia" "i915" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];
    };

    hardware.nvidia = {
      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      powerManagement.enable = false;
      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of
      # supported GPUs is at:
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
      # Only available from driver 515.43.04+
      # Currently alpha-quality/buggy, so false is currently the recommended setting.
      open = false;

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package =
        if cfg.driverType == "custom"
        then cfg.customDriverPackage
        else config.boot.kernelPackages.nvidiaPackages.${cfg.driverType};

      prime = {
        sync.enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };
}
