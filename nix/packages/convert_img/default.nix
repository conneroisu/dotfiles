{
  pkgs,
  namespace,
  ...
}:
pkgs.writeShellScriptBin "convert_img" ''
  ${pkgs."${namespace}".python-venv}/bin/python ${./convert_img.py} $@
''
