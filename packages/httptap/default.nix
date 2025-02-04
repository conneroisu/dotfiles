{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # You also have access to your flake's inputs.
  inputs,
  # The namespace used for your flake, defaulting to "internal" if not set.
  namespace,
  # All other arguments come from NixPkgs. You can use `pkgs` to pull packages or helpers
  # programmatically or you may add the named attributes as arguments here.
  pkgs,
  stdenv,
  ...
}:
pkgs.buildGoModule rec {
  pname = "httptap";
  version = "0.0.8";

  src = pkgs.fetchFromGitHub {
    owner = "monasticacademy";
    repo = "httptap";
    rev = "v${version}";
    sha256 = "sha256-1BtV5ao5dAKSINdUdJD/wxTMFXXiP8Vy1A7gQfVIsUQ=";
  };

  vendorHash = "sha256-hzNHrh4Vlaytl+RvgFe0xKxc5IA6GPzarjuTM7CU9no=";
  subPackages = ["."];
  proxyVendor = true;

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = with lib; {
    description = "HTTP linux cli proxy for monitoring and manipulating HTTP/HTTPS traffic";
    homepage = "https://github.com/monasticacademy/httptap";
    license = licenses.mit;
    maintainers = with maintainers; [
      connerohnesorge
      conneroisu
    ];
    mainProgram = "httptap";
  };
}
