{
  delib,
  inputs,
  pkgs,
  moduleSystem,
  ...
}:
delib.rice {
  name = "dark";
  home = {
    imports = [inputs.stylix.homeModules.stylix];
    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyodark.yaml";
      image = ./../../assets/klaus-desktop.jpeg;
      targets = {
        zathura.enable = true;
      };
    };
  };
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
        qt.enable = true;
        plymouth.enable = false;
        gnome.enable = true;
        gtk.enable = true;
        spicetify.enable = true;
      };
    };
  };
}
