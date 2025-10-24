/**
Z.AI Claude
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;

  program = pkgs.writeShellApplication {
    name = "zlaude";
    text = builtins.readFile ./zlaude.sh;
    excludeShellChecks = [
      "SC2068"
      "SC2155"
    ];
    runtimeEnv = {
      "ANTHROPIC_DEFAULT_HAIKU_MODEL" = "glm-4.6";
      "ANTHROPIC_DEFAULT_SONNET_MODEL" = "glm-4.6";
      "ANTHROPIC_DEFAULT_OPUS_MODEL" = "glm-4.6";
    };
  };
in
  delib.module {
    name = "programs.zlaude";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [program];
    };

    darwin.ifEnabled = {
      environment.systemPackages = [program];
    };
  }
