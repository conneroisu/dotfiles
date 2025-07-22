{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Node.js and package managers
    nodejs_20
    bun

    # Development tools
    git

    # Database tools
    sqlite

    # Build dependencies that some npm packages might need
    python3
    gcc
    gnumake
    pkg-config
  ];

  shellHook = ''
    echo "Frontend development environment"
    echo "Node.js version: $(node --version)"
    echo "Bun version: $(bun --version)"

    # Install dependencies if node_modules doesn't exist
    if [ ! -d "node_modules" ]; then
      echo "Installing dependencies..."
      bun install
    fi

    # Set NODE_ENV for development by default
    export NODE_ENV=''${NODE_ENV:-development}

    echo ""
    echo "Available commands:"
    echo "  bun run dev     - Start development server"
    echo "  bun run build   - Build for production (set NODE_ENV=production)"
    echo "  bun run lint    - Run linter"
    echo "  bun run format  - Check formatting"
    echo ""
    echo "To build for production: NODE_ENV=production bun run build"
  '';
}
