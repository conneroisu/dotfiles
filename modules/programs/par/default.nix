{
  lib,
  pkgs,
  delib,
  ...
}:
delib.module {
  name = "par";

  packages = [
    (pkgs.rustPlatform.buildRustPackage rec {
      pname = "par";
      version = "0.1.0";

      src = ./.;

      cargoLock = {
        lockFile = ./Cargo.lock;
      };

      nativeBuildInputs = with pkgs; [
        pkg-config
      ];

      buildInputs = with pkgs; [
        openssl
      ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        pkgs.darwin.apple_sdk.frameworks.Security
        pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
      ];

      meta = {
        description = "Parallel Claude Code Runner - Run Claude Code CLI across multiple Git worktrees simultaneously";
        homepage = "https://github.com/conneroisu/dotfiles";
        license = lib.licenses.mit;
        maintainers = [ "Conner Ohnesorge <connerohnesorge@outlook.com>" ];
        mainProgram = "par";
      };
    })
  ];

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.par ];
  };

  darwin.ifEnabled = {
    environment.systemPackages = [ pkgs.par ];
  };

  home.ifEnabled = {
    home.packages = [ pkgs.par ];
  };
}