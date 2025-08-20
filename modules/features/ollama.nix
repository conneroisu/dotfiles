/**
 * Ollama Feature Module
 *
 * Enables Ollama, a local LLM inference server, with automatic hardware acceleration
 * detection and Open WebUI integration for a complete local AI development experience.
 *
 * Features:
 * - Automatic hardware acceleration (NVIDIA CUDA, AMD ROCm, or CPU fallback)
 * - Pre-configured with gpt-oss:20b model loading
 * - Open WebUI web interface for model interaction
 * - NixOS service integration with proper systemd management
 *
 * Dependencies:
 * - Automatically detects myconfig.features.nvidia or myconfig.features.amd for acceleration
 * - Only available on NixOS (requires systemd services)
 */
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.ollama";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      environment.systemPackages = with pkgs; [
        ollama
      ];

      services = {
        ollama = {
          enable = true;
          loadModels = ["gpt-oss:20b"];
          acceleration =
            if myconfig.features.amd.enable
            then "rocm"
            else if myconfig.features.nvidia.enable
            then "nvidia"
            else "cpu";
        };
        open-webui.enable = true;
      };
    };
  }
