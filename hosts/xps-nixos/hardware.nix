{
  modulesPath,
  config,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  hardware.cpu.intel.updateMicrocode = pkgs.lib.mkDefault config.hardware.enableRedistributableFirmware;
}
