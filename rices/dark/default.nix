{
  delib,
  inputs,
  pkgs,
  ...
}:
delib.rice {
  name = "dark";
  nixos.imports = [inputs.stylix.nixosModules.stylix];
  nixos.stylix = {
    enable = true;
    autoEnable = true;
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
}
