/**
  # Program Module: proton-x (Proton Suite Applications)
  
  ## Description
  Bundles Proton's privacy-focused applications including Proton Mail
  desktop client and Proton Pass password manager. Provides secure,
  end-to-end encrypted email and password management solutions.
  
  ## Platform Support
  - ✅ NixOS (full support)
  - 🔶 Darwin (planned via Homebrew)
  
  ## What This Enables
  - **Proton Mail Desktop**: Native email client
  - **Proton Pass**: Password manager application
  
  ## Applications
  ### Proton Mail Desktop
  - Native desktop email client
  - End-to-end encryption
  - Multiple account support
  - Offline access to emails
  - Calendar integration
  - Secure email composition
  
  ### Proton Pass
  - Password manager with E2E encryption
  - Secure password generation
  - Auto-fill capabilities
  - Cross-platform sync
  - Secure notes and 2FA
  - Alias email generation
  
  ## Privacy Features
  - Zero-knowledge encryption
  - Swiss privacy laws protection
  - No tracking or ads
  - Open source clients
  - Secure key management
  - Anonymous sign-up options
  
  ## Common Use Cases
  - Privacy-conscious email communication
  - Secure password management
  - Business correspondence
  - Sensitive document exchange
  - Identity protection
  - Avoiding email surveillance
  
  ## Integration
  - Works alongside system email clients
  - Browser extension compatibility
  - Import from other password managers
  - Export capabilities for backup
  
  ## Security Model
  - Client-side encryption
  - Zero-access encryption
  - Secure Remote Password (SRP)
  - Two-factor authentication
  - Hardware key support
  
  ## Platform Notes
  ### NixOS
  - Full native application support
  - System integration
  - Auto-updates through Nix
  
  ### Darwin (Planned)
  - Will use Homebrew casks
  - Native macOS applications
  - Keychain integration planned
  
  ## Configuration
  Enabled via:
  - `myconfig.programs.proton-x.enable = true`
  - Useful for privacy-focused setups
  
  ## Note
  Named 'proton-x' to avoid conflicts with
  the Proton gaming compatibility layer.
*/
{
  delib,
  # inputs,
  # system,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "programs.proton-x";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [
        pkgs.protonmail-desktop
        pkgs.proton-pass
      ];
    };
    darwin.ifEnabled = {
      # TODO: maybe use homebrew
      # environment.systemPackages = [
      # ];
    };
  }
