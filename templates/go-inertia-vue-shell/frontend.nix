{ mkBunDerivation, ... }:
mkBunDerivation {
  pname = "go-inertia-vue-frontend";
  version = "1.0.0";

  src = ./.;

  bunNix = ./bun.nix;

  buildPhase = ''
    runHook preBuild
    bun run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r dist/* $out/
    runHook postInstall
  '';

  meta = {
    description = "Vue frontend for Go + Inertia.js application";
  };
}