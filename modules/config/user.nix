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
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          "@wheel"
          "connerohnesorge"
        ];
        allowed-users = [
          "root"
          "@wheel"
          "connerohnesorge"
        ];
      };
    };
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
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          "@wheel"
          "connerohnesorge"
        ];
        allowed-users = [
          "root"
          "@wheel"
          "connerohnesorge"
        ];
      };
    };
    users = {
      groups.${username} = {};
      groups.nordvpn = {};

      users.${username} = {
        home = "/home/${username}";
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
