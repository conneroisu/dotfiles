/**
# Rice Configuration: Empty Theme

## Description
Minimal theme configuration with no styling applied. Serves as a base template
for creating new themes or for systems where custom theming is not desired.
Provides the rice structure without any Stylix or color scheme configuration.

## Platform Support
- ✅ NixOS
- ✅ Darwin (macOS)
- ✅ Home Manager

## What This Provides
- **No Styling**: Clean slate without any theme modifications
- **Template Base**: Foundation for building custom rice configurations
- **Minimal Overhead**: No additional packages or configurations loaded

## Usage Notes
- Ideal for testing configurations without theming interference
- Can be extended by adding home/nixos configuration blocks
- System will use default application themes and colors
- Useful as a fallback when other themes encounter issues
*/
{
  delib,
  inputs,
  pkgs,
  moduleSystem,
  ...
}:
delib.rice {
  name = "empty";
  home = {};
  nixos = {};
}
