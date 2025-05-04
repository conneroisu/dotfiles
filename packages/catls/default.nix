{pkgs, ...}:
pkgs.writers.writeRubyBin "catls" {
  libraries = [
  ];
} ''
  ${builtins.readFile ./catls.rb}
''
