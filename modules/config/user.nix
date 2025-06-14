{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "connerohnesorge";

  darwin.always = {myconfig, ...}: let
    inherit (myconfig.constants) username;
  in {
    users = {
      groups.${username} = {};
      users.${username} = {
        home = "/Users/${username}";
      };
    };
  };

  nixos.always = {myconfig, ...}: let
    inherit (myconfig.constants) username;
  in {
    users = {
      groups.${username} = {};
      groups.nordvpn = {};

      users.${username} = {
        home = "/home/${username}";
        isNormalUser = true;
        initialPassword = "password";

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
