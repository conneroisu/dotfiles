/**
  # Feature Module: Power Efficiency
  
  ## Description
  Optimizes system power consumption for laptops and mobile devices.
  Enables advanced power management with TLP (TLP Linux Advanced Power
  Management) while disabling the simpler power-profiles-daemon to
  avoid conflicts.
  
  ## Platform Support
  - ✅ NixOS
  - ❌ Darwin (macOS has native power management)
  
  ## What This Enables
  - **TLP**: Advanced power management for battery life optimization
  - **Disables**: power-profiles-daemon (prevents conflicts)
  
  ## TLP Features
  - CPU frequency scaling and governor selection
  - Disk APM level and spin down timeout
  - SATA aggressive link power management
  - PCI Express active state power management
  - WiFi, Bluetooth, and WWAN power saving
  - USB autosuspend with device blacklisting
  - Audio codec power management
  - Battery charge thresholds (ThinkPads)
  
  ## Power Optimization
  - Automatic switching between AC and battery profiles
  - Processor boost control based on power source
  - Turbo boost limitation on battery
  - Runtime power management for PCI devices
  - Optimal settings for SSDs and HDDs
  
  ## Benefits
  - Extended battery life (typically 20-30% improvement)
  - Reduced heat generation
  - Quieter operation (less fan activity)
  - Automatic profile switching
  - No manual intervention required
  
  ## Common Use Cases
  - Laptops requiring maximum battery life
  - Mobile workstations
  - Ultrabooks with limited battery capacity
  - Devices used frequently on battery power
  
  ## Note
  TLP is chosen over power-profiles-daemon for its more comprehensive
  and fine-grained control over power management parameters. It provides
  better battery life optimization at the cost of slightly more complex
  configuration.
  
  ## Management
  - Check status: `tlp-stat`
  - Force battery mode: `tlp bat`
  - Force AC mode: `tlp ac`
*/
{delib, ...}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.power-efficient";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      services = {
        tlp.enable = true;
        power-profiles-daemon.enable = false;
      };
    };
  }
