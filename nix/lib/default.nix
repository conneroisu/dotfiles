{
  lib,
  # inputs,
  # namespace,
  # snowfall-inputs,
}: let
  file-name-regex = "(.*)\\.(.*)$";
in rec {
  ## Override a package's metadata
  ##
  ## ```nix
  ## let
  ##  new-meta = {
  ##    description = "My new description";
  ##  };
  ## in
  ##  lib.override-meta new-meta pkgs.hello
  ## ```
  ##
  #@ Attrs -> Package -> Package
  override-meta = meta: package:
    package.overrideAttrs (attrs: {
      meta = (attrs.meta or {}) // meta;
    });

  ## Append text to the contents of a file
  ##
  ## ```nix
  ## fileWithText ./some.txt "appended text"
  ## ```
  ##
  #@ Path -> String -> String
  fileWithText = file: text: ''
    ${builtins.readFile file}
    ${text}'';

  ## Prepend text to the contents of a file
  ##
  ## ```nix
  ## fileWithText' ./some.txt "prepended text"
  ## ```
  ##
  #@ Path -> String -> String
  fileWithText' = file: text: ''
    ${text}
    ${builtins.readFile file}'';

  ## Create a NixOS module option.
  ##
  ## ```nix
  ## lib.mkOpt nixpkgs.lib.types.str "My default" "Description of my option."
  ## ```
  ##
  #@ Type -> Any -> String
  mkOpt = type: default: description:
    lib.mkOption {inherit type default description;};

  ## Create a NixOS module option without a description.
  ##
  ## ```nix
  ## lib.mkOpt' nixpkgs.lib.types.str "My default"
  ## ```
  ##
  #@ Type -> Any -> String
  mkOpt' = type: default: mkOpt type default null;

  ## Create a boolean NixOS module option.
  ##
  ## ```nix
  ## lib.mkBoolOpt true "Description of my option."
  ## ```
  ##
  #@ Type -> Any -> String
  mkBoolOpt = mkOpt lib.types.bool;

  ## Create a boolean NixOS module option without a description.
  ##
  ## ```nix
  ## lib.mkBoolOpt true
  ## ```
  ##
  #@ Type -> Any -> String
  mkBoolOpt' = mkOpt' lib.types.bool;

  enabled = {
    ## Quickly enable an option.
    ##
    ## ```nix
    ## services.nginx = enabled;
    ## ```
    ##
    #@ true
    enable = true;
  };

  disabled = {
    ## Quickly disable an option.
    ##
    ## ```nix
    ## services.nginx = enabled;
    ## ```
    ##
    #@ false
    enable = false;
  };

  # Split an address to get its host name or ip and its port.
  # Type: String -> Attrs
  # Usage: get-address-parts "bismuth:3000"
  #   result: { host = "bismuth"; port = "3000"; }
  get-address-parts = address: let
    address-parts = builtins.split ":" address;
    ip = builtins.head address-parts;
    host =
      if ip == ""
      then "127.0.0.1"
      else ip;
    port =
      if builtins.length address-parts != 3
      then ""
      else lib.lists.last address-parts;
  in {
    inherit host port;
  };

  ## Create proxy configuration for NGINX virtual hosts.
  ##
  ## ```nix
  ## services.nginx.virtualHosts."example.com" = lib.network.create-proxy {
  ##   port = 3000;
  ##   host = "0.0.0.0";
  ##   proxy-web-sockets = true;
  ##   extra-config = {
  ##     forceSSL = true;
  ##   };
  ## }
  ## ``
  ##
  #@ { port: Int ? null, host: String ? "127.0.0.1", proxy-web-sockets: Bool ? false, extra-config: Attrs ? { } } -> Attrs
  create-proxy = {
    port ? null,
    host ? "127.0.0.1",
    proxy-web-sockets ? false,
    extra-config ? {},
  }:
    assert lib.errors.trace (port != "" && port != null) "port cannot be empty";
    assert lib.errors.trace (host != "") "host cannot be empty";
      extra-config
      // {
        locations =
          (extra-config.locations or {})
          // {
            "/" =
              (extra-config.locations."/" or {})
              // {
                proxyPass = "http://${host}${
                  if port != null
                  then ":${builtins.toString port}"
                  else ""
                }";

                proxyWebsockets = proxy-web-sockets;
              };
          };
      };

  ## Split a file name and its extension.
  ## Example Usage:
  ## ```nix
  ## split-file-extension "my-file.md"
  ## ```
  ## Result:
  ## ```nix
  ## [ "my-file" "md" ]
  ## ```
  #@ String -> [String]
  split-file-extension = file: let
    match = builtins.match file-name-regex file;
  in
    assert lib.errors.trace (match != null) "lib.snowfall.split-file-extension: File must have an extension to split."; match;

  ## Check if a file name has a file extension.
  ## Example Usage:
  ## ```nix
  ## has-any-file-extension "my-file.txt"
  ## ```
  ## Result:
  ## ```nix
  ## true
  ## ```
  #@ String -> Bool
  has-any-file-extension = file: let
    match = builtins.match file-name-regex (toString file);
  in
    match != null;

  ## Get the file extension of a file name.
  ## Example Usage:
  ## ```nix
  ## get-file-extension "my-file.final.txt"
  ## ```
  ## Result:
  ## ```nix
  ## "txt"
  ## ```
  #@ String -> String
  get-file-extension = file:
    if has-any-file-extension file
    then let
      match = builtins.match file-name-regex (toString file);
    in
      lib.lists.last match
    else "";

  ## Check if a file name has a specific file extension.
  ## Example Usage:
  ## ```nix
  ## has-file-extension "txt" "my-file.txt"
  ## ```
  ## Result:
  ## ```nix
  ## true
  ## ```
  #@ String -> String -> Bool
  has-file-extension = extension: file:
    if has-any-file-extension file
    then extension == get-file-extension file
    else false;

  ## Get the parent directory for a given path.
  ## Example Usage:
  ## ```nix
  ## get-parent-directory "/a/b/c"
  ## ```
  ## Result:
  ## ```nix
  ## "/a/b"
  ## ```
  #@ Path -> Path
  get-parent-directory = lib.fp.compose baseNameOf dirOf;

  ## Get the file name of a path without its extension.
  ## Example Usage:
  ## ```nix
  ## get-file-name-without-extension ./some-directory/my-file.pdf
  ## ```
  ## Result:
  ## ```nix
  ## "my-file"
  ## ```
  #@ Path -> String
  get-file-name-without-extension = path: let
    file-name = baseNameOf path;
  in
    if has-any-file-extension file-name
    then builtins.concatStringsSep "" (lib.lists.init (split-file-extension file-name))
    else file-name;
}
