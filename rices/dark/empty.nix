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
  nixos = { };
}
