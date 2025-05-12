{
  lib,
  pkgs,
  namespace,
  config,
  ...
}:
with lib; let
  cfg = config.${namespace}.package-sets.office;
in {
  options.${namespace}.package-sets.office = with types; {
    enable = mkEnableOption "Office support";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libreoffice
    ];
  };
}
