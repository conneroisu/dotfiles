{
  config,
  pkgs,
  lib,
  namespace,
  inputs,
  ...
}:
with lib; let
  cfg = config.${namespace}.hardware.nvidia;
in {
  options.${namespace}.hardware.nvidia = with types; {
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
    services = {
      # Load nvidia driver for Xorg and Wayland
      xserver.videoDrivers = ["nvidia"];
    };

    environment.variables = {
      CUDA_PATH = pkgs.cudatoolkit;
      EXTRA_LDFLAGS = "-L/lib -L${
        pkgs.lib.makeLibraryPath [
          pkgs.linuxPackages.nvidia_x11
        ]
      }";
    };

    environment.systemPackages =
      (with inputs; [
        ])
      ++ (with pkgs; [
        nvtopPackages.nvidia
        linuxPackages.nvidia_x11
        nvidia-docker
        nvidia-container-toolkit

        cudatoolkit_11
        nvtopPackages.full
      ]);

    hardware.nvidia = {
      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      powerManagement.enable = false;
      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;

      forceFullCompositionPipeline = true;
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
      # package = config.boot.kernelPackages.nvidiaPackages.${cfg.driverType};
      package =
        if cfg.driverType == "custom"
        then cfg.customDriverPackage
        else config.boot.kernelPackages.nvidiaPackages.${cfg.driverType};
      # package = config.boot.kernelPackages.nvidiaPackages.beta.overrideAttrs {
      #   version = "550.40.07";
      #   # the new driver
      #   src = pkgs.fetchurl
      #       {
      #         url = "https://download.nvidia.com/XFree86/Linux-x86_64/550.40.07/NVIDIA-Linux-x86_64-550.40.07.run";
      #         sha256 = "sha256-KYk2xye37v7ZW7h+uNJM/u8fNf7KyGTZjiaU03dJpK0=";
      #       };
      # };
    };
    hardware = {
      # Enable OpenGL
      graphics = {enable = true;};
    };
  };
}
