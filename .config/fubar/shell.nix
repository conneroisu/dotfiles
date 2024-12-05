{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  name = "fabric-shell";
  packages = with pkgs; [
    ruff # Linter
    basedpyright # Language server

    # Required for Devshell
    gtk3
    gtk-layer-shell
    cairo
    gobject-introspection
    libdbusmenu-gtk3
    gdk-pixbuf
    gnome.gnome-bluetooth
    cinnamon.cinnamon-desktop
    (python3.withPackages (
      ps: with ps; [
        setuptools
        wheel
        build
        (ps.buildPythonPackage rec {
          pname = "fabric";
          version = "unstable";
          format = "setuptools";

          src = pkgs.fetchFromGitHub {
            owner = "Fabric-Development";
            repo = "fabric";
            rev = "main"; # or specific commit hash
            sha256 = "sha256-mZml8/JEDVArKF8OjfBcw9AG2UQsFJfb2Re+Sb+eUho=";
          };

          # Add any required dependencies here
          propagatedBuildInputs = with ps; [
            psutil
            click
            pytest
            pycairo
            loguru
            pygobject3
            pygobject-stubs
          ];
        })
      ]
    ))
  ];
}
