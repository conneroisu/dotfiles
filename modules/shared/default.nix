{
  lib,
  pkgs,
  inputs,
  system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  config,
  ...
}: {
  programs = {
    direnv.enable = true;
    direnv.nix-direnv.enable = true;
    ssh = {
      extraConfig = ''
        SetEnv TERM=xterm-256color
      '';
    };
  };

  fonts.packages = with pkgs;
    [
      nerd-fonts.code-new-roman
      corefonts
      vistafonts
    ]
    ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
}
