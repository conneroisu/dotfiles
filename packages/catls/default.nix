{
  pkgs,
  namespace,
  ...
}:
pkgs.writeShellScriptBin "catls" ''
  ${pkgs."${namespace}".python-venv}/bin/python ${./catls.py} $@
''
