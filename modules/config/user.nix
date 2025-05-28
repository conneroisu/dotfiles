{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "connerohnesorge";

  nixos.always = {myconfig, ...}: let
    inherit (myconfig.constants) username;
  in {
    users = {
      groups.${username} = {};
      groups.nordvpn = {};

      users.${username} = {
        isNormalUser = true;
        extraGroups = [
          "networkmanager"
          "wheel"
          "docker"
          "users"
          "nordvpn"
        ];

        shell = pkgs.zsh;
      };
    };
  };
}
