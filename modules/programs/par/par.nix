{
  pkgs,
  lib,
  delib,
  ...
}: let
  inherit (delib) singleEnableOption;
  program = pkgs.buildGoModule rec {
    pname = "par";
    version = "0.1.0";
    
    src = ./.;
    
    vendorHash = null; # Will need to be updated after go mod tidy
    
    meta = with lib; {
      description = "Parallel Claude Code Runner - Run Claude Code CLI across multiple Git worktrees simultaneously";
      homepage = "https://github.com/conneroisu/dotfiles";
      license = licenses.mit;
      maintainers = [ "Conner Ohnesorge <connerohnesorge@outlook.com>" ];
      mainProgram = "par";
    };
  };
in
  delib.module {
    name = "programs.par";
    options = singleEnableOption false;
    nixos.ifEnabled = {
      environment.systemPackages = [
        program
      ];
    };
    darwin.ifEnabled = {
      environment.systemPackages = [
        program
      ];
    };
    home.ifEnabled = {
      home.packages = [
        program
      ];
    };
  }
