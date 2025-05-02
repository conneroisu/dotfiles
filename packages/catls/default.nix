{
  pkgs,
  namespace,
  ...
}:
pkgs.writeShellScriptBin "clean_media" ''
  ${pkgs."${namespace}".python-venv}/bin/python ${./catls.py} $@
''
