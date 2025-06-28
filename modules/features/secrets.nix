/**
  # Feature Module: Secrets Management
  
  ## Description
  Secure credential and secrets management tools for handling sensitive
  data like passwords, API keys, and certificates. Currently provides
  Proton Pass integration with SOPS prepared for future secret operations.
  
  ## Platform Support
  - ✅ NixOS
  - ❌ Darwin (would need platform-specific adaptations)
  
  ## What This Enables
  - **Proton Pass**: Secure password manager from Proton
  - **SOPS** (commented): Secrets operations for configuration files
  
  ## Current Tools
  ### Proton Pass
  - End-to-end encrypted password manager
  - Integration with Proton ecosystem
  - Secure password generation
  - Cross-platform synchronization
  - Zero-knowledge architecture
  
  ## Planned Features (SOPS)
  - Encrypted secrets in Git repositories
  - Age/GPG encryption support
  - Integration with Nix configurations
  - Secure secret deployment
  - Multi-user secret sharing
  
  ## Security Model
  - Client-side encryption
  - Zero-knowledge proof
  - No plaintext secrets in configuration
  - Secure secret injection at runtime
  
  ## Common Use Cases
  - Personal password management
  - API key storage
  - Database credentials
  - Certificate management
  - Team secret sharing
  
  ## Best Practices
  - Never commit plaintext secrets
  - Use strong master passwords
  - Enable two-factor authentication
  - Regularly rotate credentials
  - Audit access logs
  
  ## Future Integration
  SOPS integration will enable:
  - Encrypted secrets in nix configs
  - Automatic secret decryption on activation
  - Git-friendly encrypted files
  - Team secret management workflows
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.secrets";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      environment.systemPackages = with pkgs; [
        # sops
        proton-pass
      ];
    };
  }
