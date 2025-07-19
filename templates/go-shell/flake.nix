{
  description = "A development shell for go";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    nixpkgs,
    treefmt-nix,
    ...
  }: let
    supportedSystems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    perSystem = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            # Add your overlays here
            # Example:
            # my-overlay = final: prev: {
            #   my-package = prev.callPackage ./my-package { };
            # };
            final.buildGoModule = prev.buildGo124Module;
          })
        ];
      };

      scripts = {
        dx = {
          exec = ''$EDITOR "$REPO_ROOT"/flake.nix'';
          description = "Edit flake.nix";
        };
        gx = {
          exec = ''$EDITOR "$REPO_ROOT"/go.mod'';
          description = "Edit go.mod";
        };
      };

      scriptPackages =
        pkgs.lib.mapAttrs
        (
          name: script:
            pkgs.writeShellApplication {
              inherit name;
              text = script.exec;
              runtimeInputs = script.deps or [];
            }
        )
        scripts;

      treefmtModule = {
        projectRootFile = "flake.nix";
        programs = {
          alejandra.enable = true; # Nix formatter
        };
      };
    in {
      devShell = pkgs.mkShell {
        name = "dev";

        # Available packages on https://search.nixos.org/packages
        packages = with pkgs;
          [
            alejandra # Nix
            nixd
            statix
            deadnix

            go_1_23 # Go Tools
            air
            golangci-lint
            gopls
            revive
            golines
            golangci-lint-langserver
            gomarkdoc
            gotests
            gotools
            reftools
            pprof
            graphviz
            goreleaser
            cobra-cli
          ]
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
          export REPO_ROOT=$(git rev-parse --show-toplevel)
        '';
      };

      packages = {
        # default = pkgs.buildGoModule {
        #   pname = "my-go-project";
        #   version = "0.0.1";
        #   src = ./.;
        #   vendorHash = "";
        #   doCheck = false;
        #   meta = with pkgs.lib; {
        #     description = "My Go project";
        #     homepage = "https://github.com/conneroisu/my-go-project";
        #     license = licenses.asl20;
        #     maintainers = with maintainers; [connerohnesorge];
        #   };
        # };
      };

      formatter = treefmt-nix.lib.mkWrapper pkgs treefmtModule;
    });
  in {
    devShells = forAllSystems (system: {
      default = perSystem.${system}.devShell;
    });

    packages = forAllSystems (
      system:
        perSystem.${system}.packages
    );

    formatter = forAllSystems (
      system:
        perSystem.${system}.formatter
    );
  };
}
