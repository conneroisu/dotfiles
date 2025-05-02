{pkgs, ...}:
pkgs.python312.withPackages (
  ps:
    with ps; [
      numpy
      requests
      pandas
      scipy
      matplotlib
      huggingface-hub
      scikitlearn
      pyarrow
      black
      requests
      mypy
      beautifulsoup4
      pillow
      pypdf
      pip
      sympy
    ]
)
