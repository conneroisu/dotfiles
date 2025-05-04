{pkgs, ...}:
pkgs.writers.writePerlBin "catls" {
  # No extra CPAN modules needed—your script only uses core Perl modules.
  # If you later depend on a CPAN package (e.g. boolean), you can uncomment:
  # libraries = [ pkgs.perlPackages.boolean ];
} ''
  ${builtins.readFile ./catls.pl}
''
