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
    name = "xlaude";
    text = builtins.readFile ./xlaude.sh;
    excludeShellChecks = [
      "SC2068"
      "SC2155"
    ];
    runtimeEnv = {
      "ANTHROPIC_DEFAULT_HAIKU_MODEL" = "grok-code-fast-1";
      "ANTHROPIC_DEFAULT_SONNET_MODEL" = "grok-code-fast-1";
      "ANTHROPIC_DEFAULT_OPUS_MODEL" = "grok-code-fast-1";
    };
  };
in
  delib.module {
    name = "programs.xlaude";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [program];
    };

    darwin.ifEnabled = {
      environment.systemPackages = [program];
    };
  }
