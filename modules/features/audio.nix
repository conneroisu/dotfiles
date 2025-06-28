/**
  # Feature Module: Audio System Support
  
  ## Description
  Complete audio stack configuration using PipeWire as the primary audio
  server with compatibility layers for ALSA, PulseAudio, and JACK applications.
  Provides low-latency audio processing and professional audio capabilities.
  
  ## Platform Support
  - ✅ NixOS
  - ❌ Darwin (macOS uses CoreAudio)
  
  ## What This Enables
  - **PipeWire**: Modern audio/video server with low latency
  - **ALSA**: Advanced Linux Sound Architecture support and utilities
  - **PulseAudio**: Compatibility layer for PulseAudio applications
  - **JACK**: Professional audio connection kit compatibility
  - **Audio Tools**: sox for audio processing, alsa-utils for configuration
  
  ## Audio Stack Components
  - `pipewire`: Core audio server replacing PulseAudio and JACK
  - `alsa-lib`: Low-level audio interface
  - `alsa-utils`: Command-line tools (alsamixer, aplay, arecord)
  - `alsa-oss`: OSS compatibility for legacy applications
  - `sox`: Swiss Army knife of audio manipulation
  
  ## Features
  - Low-latency audio processing
  - Bluetooth audio support (when bluetooth feature enabled)
  - 32-bit application compatibility
  - Professional audio routing capabilities
  - Screen sharing audio capture
  
  ## Common Use Cases
  - Desktop audio for music and videos
  - Audio production and recording
  - Gaming with spatial audio
  - Video conferencing
  - Screen recording with audio
  
  ## Troubleshooting
  - Use `wpctl` for PipeWire control
  - Use `alsamixer` for hardware mixer control
  - Check `systemctl --user status pipewire*` for service status
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.audio";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      environment.systemPackages = with pkgs; [
        ## Audio
        alsa-oss
        alsa-utils
        alsa-lib
        sox
      ];

      services = {
        ## Audio
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
        };
      };
    };
  }
