{
  lib,
  pkgs,
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
