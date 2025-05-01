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
      torch
      debugpy
      opencv4
      torchvision
      selenium
      pyarrow
      psycopg
      mysqlclient
      ollama
      black
      requests
      mypy
      torchdiffeq
      beautifulsoup4
      pillow
      pypdf
      pytest
      pip
      sympy
    ]
)
