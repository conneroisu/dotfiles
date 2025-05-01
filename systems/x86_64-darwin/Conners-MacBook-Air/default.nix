{
  # lib,
  pkgs,
  inputs,
  # namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  # system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  config,
  ...
}: {
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    # Macos Only
    aerospace
    raycast
    utm
    xcodes
  ];

  # Set Git commit hash for darwin-version.
  system = {
    # configurationRevision = self.rev or self.dirtyRev or null;
    stateVersion = 5;
    defaults = {
      dock.autohide = true;

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
        Dragging = true;
      };
    };
  };

  environment.shells = [pkgs.zsh];
  users.users.connerohnesorge = {
    home = "/Users/connerohnesorge";
    name = "connerohnesorge";
  };

  homebrew = {
    enable = true;
    brews = [
      "goenv"
      "ollama"
      "go-task"
    ];
    casks = [
      # "ghdl"
    ];
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "connerohnesorge";
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
    };
    mutableTaps = false;
  };
  security.pam.services.sudo_local.touchIdAuth = true;
  system.activationScripts.applications.text = let
    env = pkgs.buildEnv {
      name = "system-applications";
      paths = config.environment.systemPackages;
      pathsToLink = "/Applications";
    };
  in
    pkgs.lib.mkForce ''
      # Set up applications.
      echo "setting up /Applications..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read -r src; do
        app_name=$(basename "$src")
        echo "copying $src" >&2
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
      done
    '';
}
