{
  description = "TanStack Start development shell with auth system and dashboard";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # TanStack Start application package
        tanstack-app = pkgs.buildNpmPackage rec {
          pname = "tanstack-auth-app";
          version = "0.1.0";

          src = pkgs.lib.cleanSource ./.;

          # This hash needs to be calculated - use `lib.fakeHash` for initial builds
          npmDepsHash = pkgs.lib.fakeHash;

          nativeBuildInputs = with pkgs; [
            nodejs_20
            python3 # Required for some native dependencies
          ];

          buildInputs = with pkgs; [
            sqlite # Required for better-sqlite3 native compilation
          ];

          # Configure build environment
          preBuild = ''
            # Set up environment for native compilation
            export npm_config_build_from_source=true
            export npm_config_sqlite=${pkgs.sqlite.dev}
            
            # Ensure we have all required build tools
            export PYTHON=${pkgs.python3}/bin/python
          '';

          buildPhase = ''
            runHook preBuild
            
            # Install dependencies
            npm ci --offline --cache .npm-cache
            
            # Run the build
            npm run build
            
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            
            mkdir -p $out/bin $out/lib $out/share
            
            # Copy built application
            if [ -d .output ]; then
              cp -r .output/* $out/lib/
            else
              echo "Error: .output directory not found after build"
              exit 1
            fi
            
            # Copy package.json and other runtime files
            cp package.json $out/lib/
            if [ -f drizzle.config.ts ]; then
              cp drizzle.config.ts $out/lib/
            fi
            
            # Create the main executable script
            cat > $out/bin/tanstack-auth-app << 'EOF'
            #!/usr/bin/env bash
            set -euo pipefail
            
            # Set up runtime environment
            export NODE_ENV=''${NODE_ENV:-production}
            export PORT=''${PORT:-3000}
            export DATABASE_URL=''${DATABASE_URL:-file:./data.db}
            
            # Create data directory if it doesn't exist
            mkdir -p "$(dirname "''${DATABASE_URL#file:}")" 2>/dev/null || true
            
            # Run the application
            cd $out/lib
            exec ${pkgs.nodejs_20}/bin/node server/index.mjs "$@"
            EOF
            
            chmod +x $out/bin/tanstack-auth-app
            
            # Create a helper script for database operations
            cat > $out/bin/tanstack-auth-db << 'EOF'
            #!/usr/bin/env bash
            set -euo pipefail
            
            # Database management script
            export NODE_ENV=''${NODE_ENV:-production}
            export DATABASE_URL=''${DATABASE_URL:-file:./data.db}
            
            cd $out/lib
            
            case "''${1:-help}" in
              migrate)
                echo "Running database migrations..."
                ${pkgs.nodejs_20}/bin/npx drizzle-kit migrate
                ;;
              studio)
                echo "Starting Drizzle Studio..."
                ${pkgs.nodejs_20}/bin/npx drizzle-kit studio
                ;;
              *)
                echo "Usage: $0 {migrate|studio}"
                echo "  migrate - Run database migrations"
                echo "  studio  - Start Drizzle Studio"
                exit 1
                ;;
            esac
            EOF
            
            chmod +x $out/bin/tanstack-auth-db
            
            runHook postInstall
          '';

          # Enable parallel building for faster builds
          enableParallelBuilding = true;

          meta = with pkgs.lib; {
            description = "TanStack Start application with authentication and dashboard";
            homepage = "https://github.com/conneroisu/dotfiles";
            license = licenses.mit;
            maintainers = with maintainers; [ ];
            platforms = platforms.unix;
            mainProgram = "tanstack-auth-app";
          };
        };

      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Node.js environment
            nodejs_20
            nodePackages.npm
            nodePackages.pnpm
            nodePackages.yarn
            
            # TypeScript and development tools
            nodePackages.typescript
            nodePackages.typescript-language-server
            
            # Linting and formatting
            nodePackages.eslint
            nodePackages.prettier
            
            # Git for version control
            git
            
            # Build tools
            pkg-config
            
            # Optional: Database tools for development
            sqlite
            postgresql
            
            # Optional: Testing tools
            # Note: Jest will be installed via npm in package.json
            
            # Development utilities
            jq
            curl
            
            # Process management
            nodePackages.pm2
          ];

          shellHook = ''
            echo "🚀 TanStack Start Development Environment"
            echo "📦 Node.js version: $(node --version)"
            echo "📦 npm version: $(npm --version)"
            echo ""
            echo "🔧 Available commands:"
            echo "  npm run dev      - Start development server"
            echo "  npm run build    - Build for production"
            echo "  npm run start    - Start production server"
            echo "  npm run lint     - Run ESLint"
            echo "  npm run format   - Format code with Prettier"
            echo ""
            echo "📚 Quick start:"
            echo "  npm install      - Install dependencies"
            echo "  npm run dev      - Start development"
            echo ""
            
            # Set up environment variables
            export NODE_ENV=development
            export PORT=3000
            
            # Create .env file if it doesn't exist
            if [ ! -f .env ]; then
              cat > .env << 'EOF'
# TanStack Start Environment Variables
NODE_ENV=development
PORT=3000

# Database (if using SQLite)
DATABASE_URL=file:./dev.db

# Session Secret (generate a secure one for production)
SESSION_SECRET=your-super-secret-session-key-change-this-in-production

# Authentication Provider Settings (optional - configure as needed)
# GITHUB_CLIENT_ID=your_github_client_id
# GITHUB_CLIENT_SECRET=your_github_client_secret
# GOOGLE_CLIENT_ID=your_google_client_id
# GOOGLE_CLIENT_SECRET=your_google_client_secret

# CORS Settings
CORS_ORIGIN=http://localhost:3000
EOF
              echo "📄 Created .env file with default settings"
            fi
          '';
        };

        # Package outputs
        packages = {
          default = tanstack-app;
          tanstack-auth-app = tanstack-app;
        };

        # Applications for running
        apps = {
          default = {
            type = "app";
            program = "${tanstack-app}/bin/tanstack-auth-app";
          };
          tanstack-auth-app = {
            type = "app";
            program = "${tanstack-app}/bin/tanstack-auth-app";
          };
          tanstack-auth-db = {
            type = "app";
            program = "${tanstack-app}/bin/tanstack-auth-db";
          };
        };

        # Development and testing
        checks = {
          build = tanstack-app;
        };
      }
    );
}