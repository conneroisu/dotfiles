/**
Kimi K2 Claude
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;

  program = pkgs.writeShellApplication {
    name = "klaude";
    text = builtins.readFile ./klaude.sh;
    excludeShellChecks = [
      "SC2068"
      "SC2155"
    ];
    runtimeEnv = {
      "ANTHROPIC_DEFAULT_HAIKU_MODEL" = "kimi-for-coding";
      "ANTHROPIC_DEFAULT_SONNET_MODEL" = "kimi-for-coding";
      "ANTHROPIC_DEFAULT_OPUS_MODEL" = "kimi-for-coding";
    };
  };
in
  delib.module {
    name = "programs.klaude";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [program];
    };

    darwin.ifEnabled = {
      environment.systemPackages = [program];
    };
  }
