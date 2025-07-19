/**
# Feature Module: Darknet (Privacy & Security)

## Description
Enhanced privacy and security configuration for systems requiring
secure network access and protection against intrusion attempts.
Provides VPN connectivity and automated threat response.

## Platform Support
- ✅ NixOS
- ❌ Darwin (would require different tooling)

## What This Enables
- **Tailscale**: Zero-config VPN for secure mesh networking
- **Fail2ban**: Intrusion prevention system that blocks malicious IPs

## Security Features
### Tailscale VPN
- Secure peer-to-peer connectivity
- Zero-trust network architecture
- Automatic NAT traversal
- End-to-end encryption
- Access control lists (ACLs)

### Fail2ban Protection
- Monitors system logs for intrusion attempts
- Automatically bans IPs after failed login attempts
- Protects SSH, web services, and other exposed services
- Configurable ban duration and thresholds

## Common Use Cases
- Secure remote access to home network
- Protection for internet-facing services
- Private networking between devices
- Enhanced security for servers
- Defense against brute force attacks

## Network Security
- Creates secure overlay network with Tailscale
- Provides defense-in-depth with fail2ban
- Suitable for both personal and professional use

## Management
- Tailscale: `tailscale status`, `tailscale up`
- Fail2ban: `fail2ban-client status`
- Check banned IPs: `fail2ban-client status sshd`
*/
{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
in
  delib.module {
    name = "features.darknet";

    options = singleEnableOption false;

    nixos.ifEnabled = {myconfig, ...}: {
      services = {
        # tailscale.enable = true;
        fail2ban.enable = true;
      };
    };
  }
