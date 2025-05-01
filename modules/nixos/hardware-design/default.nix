{
  lib,
  pkgs,
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  config,
  ...
}:
with lib; let
  cfg = config.${namespace}.package-sets.hardware-design;
in {
  options.${namespace}.package-sets.hardware-design = with types; {
    enable = mkEnableOption "Hardware design support";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      quartus-prime-lite
      kicad
      xilinx-bootgen
    ];
  };
}
