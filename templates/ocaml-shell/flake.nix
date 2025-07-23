{
  description = "A development shell for OCaml";
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
        overlays = [];
      };

      scripts = {
        dx = {
          exec = ''$EDITOR "$REPO_ROOT"/flake.nix'';
          description = "Edit flake.nix";
        };
        ox = {
          exec = ''$EDITOR "$REPO_ROOT"/dune-project'';
          description = "Edit dune-project";
        };
        run-example = {
          exec = ''dune exec examples/simple_example.exe'';
          description = "Run the simple example program";
        };
        build = {
          exec = ''dune build'';
          description = "Build the project";
        };
        test = {
          exec = ''dune runtest'';
          description = "Run tests";
        };
        clean = {
          exec = ''dune clean'';
          description = "Clean build artifacts";
        };
        fmt = {
          exec = ''dune build @fmt --auto-promote'';
          description = "Format code with ocamlformat";
        };
        docs = {
          exec = ''dune build @doc && echo "Documentation built in _build/default/_doc/_html/"'';
          description = "Build documentation";
        };
        repl = {
          exec = ''dune utop'';
          description = "Start REPL with project loaded";
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
          ocamlformat.enable = true; # OCaml formatter
        };
      };
    in {
      devShell = pkgs.mkShell {
        name = "ocaml-dev";

        # Available packages on https://search.nixos.org/packages
        packages = with pkgs;
          [
            # Nix tooling
            alejandra
            nixd
            statix
            deadnix

            # OCaml core toolchain
            ocaml
            dune_3
            opam
            ocamlPackages.findlib

            # Development tools
            ocamlformat
            ocamlPackages.merlin
            ocamlPackages.utop
            ocamlPackages.ocp-indent
            ocamlPackages.ocaml-lsp
            ocamlPackages.odoc # Documentation generation
            ocamlPackages.ounit2 # Additional testing framework

            # Essential libraries for most OCaml projects
            ocamlPackages.base
            ocamlPackages.stdio
            ocamlPackages.core # Jane Street's standard library

            # Popular PPX extensions
            ocamlPackages.ppx_deriving
            ocamlPackages.ppx_jane # Jane Street PPX collection
            ocamlPackages.ppx_inline_test
            ocamlPackages.ppx_expect

            # Testing frameworks
            ocamlPackages.alcotest
            ocamlPackages.qcheck # Property-based testing

            # Commonly used libraries
            ocamlPackages.lwt # Async programming
            ocamlPackages.cmdliner # Command-line parsing
            ocamlPackages.yojson # JSON handling
            ocamlPackages.logs # Logging

            # Build and project management
            git # For project management
            gnumake # Sometimes needed for C bindings
          ]
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
                    export REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

                    # Create .ocamlformat if it doesn't exist
                    if [ ! -f "$REPO_ROOT"/.ocamlformat ]; then
                      cat > "$REPO_ROOT"/.ocamlformat << 'EOF'
          version = 0.27.0
          profile = default
          margin = 100
          indent = 2
          break-cases = fit-or-vertical
          EOF
                    fi

                    # Setup opam if not already done (optional)
                    if [ ! -d "$HOME/.opam" ] && command -v opam >/dev/null 2>&1; then
                      echo "Setting up opam for the first time..."
                      opam init --no-setup --disable-sandboxing -y 2>/dev/null || true
                    fi

                    echo "🐪 Welcome to the OCaml Development Environment!"
                    echo "═══════════════════════════════════════════════"
                    echo "📦 OCaml version: $(ocaml -version | cut -d' ' -f4)"
                    echo "🔨 Dune version: $(dune --version)"
                    echo "📝 OCamlformat version: $(ocamlformat --version | cut -d' ' -f2)"
                    echo ""
                    echo "🛠️  Available Development Tools:"
                    echo "   • ocaml        - OCaml compiler and REPL"
                    echo "   • dune         - Modern build system"
                    echo "   • utop         - Enhanced REPL with autocompletion"
                    echo "   • ocaml-lsp    - Language server for IDE integration"
                    echo "   • ocamlformat   - Code formatter"
                    echo "   • merlin       - Editor integration for completion/navigation"
                    echo "   • odoc         - Documentation generator"
                    echo ""
                    echo "📚 Useful Libraries Included:"
                    echo "   • base, stdio  - Jane Street's enhanced standard library"
                    echo "   • core         - Industrial-strength standard library"
                    echo "   • lwt          - Cooperative threading"
                    echo "   • cmdliner     - Command-line argument parsing"
                    echo "   • yojson       - JSON processing"
                    echo "   • alcotest     - Lightweight testing framework"
                    echo "   • qcheck       - Property-based testing"
                    echo ""
                    echo "🚀 Quick Commands:"
                    echo "   • build        - Build your project (dune build)"
                    echo "   • test         - Run tests (dune runtest)"
                    echo "   • repl         - Start REPL with project loaded"
                    echo "   • fmt          - Format code"
                    echo "   • docs         - Generate documentation"
                    echo "   • clean        - Clean build artifacts"
                    echo "   • run-example  - Run the simple example program"
                    echo ""
                    echo "💡 Try: 'nix build' to create installable packages!"
                    echo "💡 Try: 'build && dune exec ocaml_template' to run the CLI!"
                    echo "═══════════════════════════════════════════════"
        '';
      };

      packages = {
        default = pkgs.ocamlPackages.buildDunePackage {
          pname = "ocaml_template";
          version = "0.1.0";
          src = ./.;

          # Runtime dependencies
          propagatedBuildInputs = with pkgs.ocamlPackages; [
            base
            stdio
            core
            lwt
            cmdliner
            yojson
            logs
            fmt
            ppx_jane
            qcheck
          ];

          # Build dependencies
          buildInputs = with pkgs.ocamlPackages; [
            dune_3
            findlib
          ];

          # Test dependencies
          checkInputs = with pkgs.ocamlPackages; [
            alcotest
            alcotest-lwt
            qcheck
            ounit2
          ];

          # Disable tests for now to focus on build
          doCheck = false;

          # Override build phase to avoid --only-packages issue
          buildPhase = ''
            runHook preBuild
            dune build --profile release lib bin examples @install
            runHook postBuild
          '';

          meta = with pkgs.lib; {
            description = "OCaml template project with modern tooling and best practices";
            longDescription = ''
              A comprehensive OCaml project template featuring:
              - Modern library ecosystem (Base, Core, Lwt)
              - Command-line interface with Cmdliner
              - JSON handling with Yojson
              - Comprehensive testing with Alcotest and QCheck
              - Async programming examples
              - Structured logging
              - Documentation with ODocs
            '';
            homepage = "https://github.com/user/ocaml-template";
            changelog = "https://github.com/user/ocaml-template/blob/main/CHANGELOG.md";
            license = licenses.mit;
            maintainers = with maintainers; [
              /*
              Add your maintainer info
              */
            ];
            platforms = platforms.unix;
          };
        };

        # Additional build targets
        lib = pkgs.ocamlPackages.buildDunePackage {
          pname = "ocaml-template-lib";
          version = "0.1.0";
          src = ./.;

          # Only build the library, not the executable
          buildPhase = ''
            runHook preBuild
            dune build lib/
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            dune install --prefix=$out --libdir=$OCAMLFIND_DESTDIR lib
            runHook postInstall
          '';

          propagatedBuildInputs = with pkgs.ocamlPackages; [
            base
            stdio
            core
            lwt
            yojson
            logs
            ppx_jane
          ];

          doCheck = false; # Skip tests for lib-only build

          meta = with pkgs.lib; {
            description = "OCaml template library only";
            license = licenses.mit;
          };
        };

        examples = pkgs.ocamlPackages.buildDunePackage {
          pname = "ocaml-template-examples";
          version = "0.1.0";
          src = ./.;

          # Build library and examples
          buildPhase = ''
            runHook preBuild
            dune build lib/ examples/
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            dune install --prefix=$out --libdir=$OCAMLFIND_DESTDIR lib examples
            runHook postInstall
          '';

          propagatedBuildInputs = with pkgs.ocamlPackages; [
            base
            stdio
            core
            lwt
            yojson
            logs
            fmt
            ppx_jane
          ];

          doCheck = false;

          meta = with pkgs.lib; {
            description = "OCaml template with examples";
            license = licenses.mit;
          };
        };
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
