# Legacy shell.nix for compatibility with non-flake Nix installations
# For the best experience, use: nix develop

let
  # Import nixpkgs
  pkgs = import <nixpkgs> {};
  
  # If flake.lock exists, try to use flake-compat for consistency
  flakeCompat = 
    if builtins.pathExists ./flake.lock then
      let
        lock = builtins.fromJSON (builtins.readFile ./flake.lock);
        flake-compat = fetchTarball {
          url = "https://github.com/edolstra/flake-compat/archive/master.tar.gz";
        };
      in
        (import flake-compat { src = ./.; }).shellNix
    else
      # Fallback shell environment when flake.lock doesn't exist
      pkgs.mkShell {
        name = "ocaml-dev-legacy";
        
        buildInputs = with pkgs; [
          # OCaml core
          ocaml
          dune_3
          opam
          
          # Development tools
          ocamlformat
          ocamlPackages.merlin
          ocamlPackages.utop
          ocamlPackages.ocaml-lsp
          ocamlPackages.findlib
          
          # Essential libraries
          ocamlPackages.base
          ocamlPackages.stdio
          ocamlPackages.alcotest
          
          # Build tools
          git
          gnumake
        ];
        
        shellHook = ''
          echo "🐪 OCaml Development Environment (Legacy Mode)"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "⚠️  You're using legacy shell.nix mode."
          echo "💡 For the best experience, use: nix develop"
          echo ""
          echo "📦 OCaml $(ocaml -version | cut -d' ' -f4) ready!"
          echo "🔨 Dune $(dune --version) available"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        '';
      };
in
  flakeCompat