{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:
with lib; let
  cfg = config.${namespace}.hardware.bluetooth;
in {
  options.${namespace}.hardware.bluetooth = with types; {
    enable = mkEnableOption "Bluetooth support";
  };

  config = mkIf cfg.enable {
    hardware = {
      bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            Name = "Hello";
            ControllerMode = "dual";
            FastConnectable = "true";
            Experimental = "true";
            Enable = "Source,Sink,Media,Socket";
          };
          Policy = {
            AutoEnable = "true";
          };
        };
      };
    };
  };
}
