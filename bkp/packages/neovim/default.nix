{
  lib,
  inputs,
  namespace,
  pkgs,
  stdenv,
  ...
}:
stdenv.mkDerivation {
  name = "neovim";
  src = pkgs.neovim;
  meta = with lib; {
    description = "Neovim";
    homepage = "https://neovim.io/";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
