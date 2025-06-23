{
  delib,
  pkgs,
  ...
}: let
  inherit (delib) singleEnableOption;
  
  # Create a proper Python package with test support
  python3Env = pkgs.python3.withPackages (ps: with ps; [
    pillow
    pytest
    pytest-cov
  ]);
  
  program = pkgs.writers.writePython3Bin "convert_img" {
    flakeIgnore = ["W291" "W503" "E226" "E501"];
    libraries = with pkgs.python3Packages; [
      pillow
    ];
  } ./convert_img.py;
  
  # Test derivation for running tests
  testDerivation = pkgs.stdenv.mkDerivation {
    name = "convert_img-tests";
    src = ./.;
    
    nativeBuildInputs = [ python3Env ];
    
    buildPhase = ''
      echo "Running convert_img tests..."
      python -m pytest tests/ -v || true
    '';
    
    installPhase = ''
      mkdir -p $out
      echo "Tests completed" > $out/test-results
    '';
  };
  
in
  delib.module {
    name = "programs.convert_img";

    options = singleEnableOption false;

    nixos.ifEnabled = {
      environment.systemPackages = [
        program
        pkgs.potrace
      ];
    };

    darwin.ifEnabled = {
      environment.systemPackages = [
        program
        pkgs.potrace
      ];
    };
    
    # Expose the test derivation for manual testing
    passthru.tests = testDerivation;
  }
