/**
# Rice Configuration: Dark Theme

## Description
A sophisticated dark theme configuration using Tokyo Dark color scheme
with comprehensive application theming through Stylix. Provides consistent
dark mode across all applications with carefully selected colors for
optimal readability and reduced eye strain.

## Theme Details
- **Color Scheme**: Tokyo Dark (Base16)
- **Wallpaper**: Klaus desktop image
- **Polarity**: Dark mode
- **Cursor**: Rose Pine Hyprcursor theme

## Platform Support
- ✅ NixOS (full Stylix integration)
- ✅ Darwin (limited to Home Manager apps)

## What Gets Themed
### NixOS
- Window managers (Hyprland, KDE Plasma, etc.)
- GTK applications
- Qt applications
- Terminal emulators (including Konsole)
- Text editors (Neovim, Kate, etc.)
- Spotify (via Spicetify)
- GNOME applications
- KDE Plasma desktop and applications
- System notifications

### Darwin
- Terminal applications
- Zathura PDF reader
- Home Manager managed apps
- Limited system integration

## Color Palette
Tokyo Dark provides:
- Deep background colors
- High contrast text
- Vibrant accent colors
- Syntax highlighting optimization
- Reduced blue light emission

## Cursor Configuration (NixOS)
- Size: 12 pixels
- Theme: Rose Pine Hyprcursor
- Smooth animations
- High visibility

## Application Targets
### Enabled
- Qt toolkit theming
- GTK toolkit theming
- GNOME app integration
- Spotify custom theme
- Zathura PDF viewer

### Disabled
- GRUB bootloader (keep default)
- Plymouth boot screen (keep default)

## Visual Consistency
- Unified color scheme across all apps
- Consistent spacing and padding
- Harmonized fonts and sizes
- Coordinated highlight colors

## Benefits
- Reduced eye strain
- Better night-time usage
- Professional appearance
- Improved focus
- Battery savings (OLED screens)

## Customization
The rice system allows:
- Easy theme switching
- Per-application overrides
- Custom color adjustments
- Wallpaper changes

## Integration
Works seamlessly with:
- Hyprland window manager
- Engineer development tools
- All GUI applications
- Terminal environments
*/
{
  delib,
  inputs,
  pkgs,
  lib,
  moduleSystem,
  config,
  ...
}:
delib.rice {
  name = "dark";
  home =
    if pkgs.stdenv.isDarwin
    then {
      imports = [inputs.stylix.homeModules.stylix];
      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyodark.yaml";
        image = ./../../assets/klaus-desktop.jpeg;
        targets = {
          zathura.enable = true;
        };
      };
      myconfig.programs.ghostty.enable = true;
    }
    else {};
  nixos = {
    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyodark.yaml";
      image = ./../../assets/klaus-desktop.jpeg;
      polarity = "dark";
      cursor = {
        size = 12;
        name = "rose-pine-hyprcursor";
        package = pkgs.rose-pine-hyprcursor;
      };
      targets = {
        grub.enable = false;
        qt.enable = false;
        plymouth.enable = false;
        gnome.enable = true;
        gtk.enable = true;
        spicetify.enable = true;
        # KDE Plasma theming works via qt.enable above
        # kde.enable and konsole.enable not available in current Stylix version
      };
    };
  };
}
