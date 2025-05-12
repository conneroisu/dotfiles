{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:
with lib; let
  cfg = config.${namespace}.hardware.audio;
in {
  options.${namespace}.hardware.audio = with types; {
    enable = mkEnableOption "Audio support";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      alsa-oss
      alsa-utils
      alsa-lib
      blueman

      sox
    ];
    hardware = {
    };

    services = {
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
    };
  };
}
