{
  description = "A development shell for go";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = inputs @ {nixpkgs, ...}: let
    supportedSystems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    pkgs = forAllSystems (system:
      import nixpkgs {
        inherit system;
        overlays = [
          inputs.nixpkgs.overlays.default
        ];
      });
    scripts = {
      dx = {
        exec = ''$EDITOR $REPO_ROOT/flake.nix'';
        description = "Edit flake.nix";
      };
      gx = {
        exec = "$EDITOR $REPO_ROOT/go.mod";
        description = "Edit go.mod";
      };
    };

    scriptPackages =
      pkgs.lib.mapAttrsToList
      (name: script: pkgs.writeShellScriptBin name script.exec)
      scripts;
  in {
    devShells.default = pkgs.mkShell {
      name = "dev";

      # Available packages on https://search.nixos.org/packages
      packages = with pkgs;
        [
          alejandra # Nix
          nixd
          statix
          deadnix

          go_1_24 # Go Tools
          air
          templ
          golangci-lint
          (buildWithSpecificGo revive)
          (buildWithSpecificGo gopls)
          (buildWithSpecificGo templ)
          (buildWithSpecificGo golines)
          (buildWithSpecificGo golangci-lint-langserver)
          (buildWithSpecificGo gomarkdoc)
          (buildWithSpecificGo gotests)
          (buildWithSpecificGo gotools)
          (buildWithSpecificGo reftools)
          pprof
          graphviz
          goreleaser
        ]
        ++ builtins.attrValues scriptPackages;

      shellHook = ''
        echo "Welcome to the rust devshell!"
      '';
    };
  };
}
