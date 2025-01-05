{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  name = "pegwings";

  languages = {
    nix.enable = true;
    go = {
      enable = true;
      package = pkgs.go;
    };
    python = {
      enable = true;
      package = pkgs.python311;
    };
  };

  packages = with pkgs; [
    git
    sqldiff
    pprof
    podman
    revive
    iferr
    impl
    golangci-lint
    golangci-lint-langserver
    gopls
    gomodifytags
    gomarkdoc
    gotests
    gotools
    templ
    sqlc
    flyctl
    air
    wireguard-tools
    (python311.withPackages (ps:
      with ps; [
        numpy
        pandas
        scipy
        matplotlib
        scikitlearn
        torch
        opencv4
        torchvision
        torchaudio
        selenium
        pyarrow
        psycopg
        mysqlclient
        ollama
        black
        requests
        uvicorn
        flask
        fastapi
        django
        gunicorn
        pydantic
        mypy
        torchdiffeq
        beautifulsoup4
        pillow
        gym
        pypdf
        pytest
        pip
        sympy
      ]))
  ];

  scripts = {
    generate.exec = ''
      cd $(git rev-parse --show-toplevel)
      go work sync
      for dir in $(go work edit -json | jq -r '.Use[].DiskPath'); do
          (cd "$dir" && go generate -v ./...)
      done
      cd -
      templ generate
    '';
    tests.exec = ''go test -v -short ./...'';
    unit-tests.exec = ''go test -v ./...'';
    lint.exec = ''
      golangci-lint run
      revive -config revive.toml $(git rev-parse --show-toplevel)/...
    '';
    latest.exec = ''
      cd $(git rev-parse --show-toplevel) && git add . && git commit -m "latest" && git push
    '';
    dx.exec = ''$EDITOR $(git rev-parse --show-toplevel)/devenv.nix'';
  };

  enterShell = ''git status'';
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  cachix.enable = true;
}
