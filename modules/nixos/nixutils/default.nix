{
  lib,
  pkgs,
  namespace,
  config,
  ...
}:
with lib; let
  cfg = config.${namespace}.nixutils;
in {
  options.${namespace}.nixutils = with types; {
    enable = mkEnableOption "Nix utilities support";
  };
  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      package = pkgs.nh;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/home/user/my-nixos-config";
    };
  };
}
