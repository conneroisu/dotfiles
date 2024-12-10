{
  self,
  pkgs,
  unstable-pkgs,
  config,
  ...
}:
let
  sharedPkgs = (import ../shared { inherit pkgs unstable-pkgs; }).environment.systemPackages;
in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    sharedPkgs
    ++ (with pkgs; [
      # Macos Only
      aerospace
      google-chrome
    ]);

  nix.settings.experimental-features = "nix-command flakes";

  # Set Git commit hash for darwin-version.
  system = {
    configurationRevision = self.rev or self.dirtyRev or null;
    stateVersion = 5;
    defaults = {
      dock.autohide = true;

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };

    };
  };

  environment.shells = [ pkgs.zsh ];
  users.users.connerohnesorge = {
    home = "/Users/connerohnesorge";
    name = "connerohnesorge";
  };

  home-manager.users.connerohnesorge = {
    home.stateVersion = "25.05";
    home.packages = with pkgs; [
      devenv
    ];
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
  nixpkgs.hostPlatform = "aarch64-darwin";
  security.pam.enableSudoTouchIdAuth = true;
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  nixpkgs.config.allowUnfree = true;
  system.activationScripts.applications.text =
    let
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