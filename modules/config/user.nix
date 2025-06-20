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
        substituters = [
          "https://cache.nixos.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
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

    nix.settings = {
      use-cgroups = true;
      max-jobs = 8;
      cores = 4;
      experimental-features = [
        "nix-command"
        "flakes"
        "cgroups"
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

    # environment = {
    #   etc."nix/nix.custom.conf".text = let
    #     # This function converts an attribute set to Nix configuration lines
    #     settingsToConf = settings:
    #       pkgs.lib.concatStringsSep "\n" (
    #         pkgs.lib.mapAttrsToList (
    #           name: value: "${name} = ${
    #             if builtins.isBool value
    #             then pkgs.lib.boolToString value
    #             else if builtins.isInt value
    #             then toString value
    #             else if builtins.isList value
    #             then pkgs.lib.concatMapStringsSep " " (x: "${toString x}") value
    #             else if builtins.isString value
    #             then value
    #             else throw "Unsupported type for nix.conf setting ${name}"
    #           }"
    #         )
    #         settings
    #       );
    #   in
    #     # Apply the function to your desired settings
    #     settingsToConf {
    #       # Add your nix settings here, for example:
    #       max-jobs = 8;
    #       experimental-features = [
    #         "nix-command"
    #         "flakes"
    #       ];
    #       trusted-users = [
    #         "root"
    #         "@wheel"
    #         "connerohnesorge"
    #       ];
    #       allowed-users = [
    #         "root"
    #         "@wheel"
    #         "connerohnesorge"
    #       ];
    #     };
    # };
  };
}
