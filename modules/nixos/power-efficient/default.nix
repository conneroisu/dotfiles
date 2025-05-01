{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:
with lib; let
  cfg = config.${namespace}.hardware.power-efficient;
in {
  options.${namespace}.hardware.power-efficient = with types; {
    enable = mkEnableOption "Audio support";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [];
    hardware = {};
    services = {
      tlp.enable = true;
      power-profiles-daemon.enable = false;
    };
  };
}
