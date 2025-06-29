# Rust Web Shell

A modern, full-stack web application template built with Rust, featuring authentication, session management, and a beautiful UI.

## Features

- 🦀 **Rust Backend** - Fast and safe backend built with Axum
- 🎨 **Modern Frontend** - TailwindCSS for styling, Alpine.js for interactivity
- 🔒 **Authentication** - Complete user registration and login system
- 📱 **Responsive Design** - Works beautifully on desktop and mobile
- ⚡ **Fast Build** - Optimized build process with asset bundling
- 🛡️ **Secure** - Password hashing, session management, and CSRF protection

## Tech Stack

- **Backend**: Rust, Axum, SQLx, SQLite
- **Frontend**: TailwindCSS, Alpine.js, TypeScript
- **Templates**: Askama
- **Session Management**: axum-sessions
- **Password Hashing**: Argon2
- **Development**: Nix, direnv, just

## Quick Start

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- [direnv](https://direnv.net/) (optional but recommended)

### Setup

1. **Enter the development environment:**
   ```bash
   nix develop
   # or if you have direnv: just cd into the directory
   ```

2. **Set up the project:**
   ```bash
   just setup
   ```

3. **Run the development server:**
   ```bash
   just dev
   ```

4. **Visit the application:**
   - Home: http://localhost:3000
   - Login: http://localhost:3000/login
   - Signup: http://localhost:3000/signup
   - Dashboard: http://localhost:3000/dashboard

## Available Commands

```bash
# Development
just setup          # Install dependencies and build assets
just dev            # Run with auto-reload
just run            # Run the application

# Database
just migrate        # Run database migrations
just migrate-create # Create a new migration
just db-reset       # Reset database

# Building
just build          # Build for production
just check          # Check code (clippy)
just fmt            # Format code

# Testing
just test           # Run tests
```

## Environment Variables

Create a `.env` file in the project root:

```bash
# Database
DATABASE_URL=sqlite:app.db

# Server
HOST=127.0.0.1
PORT=3000

# Logging
RUST_LOG=debug
```

## Project Structure

```
├── src/
│   ├── handlers/        # Request handlers
│   ├── models/          # Database models
│   ├── lib.rs          # Library setup
│   └── main.rs         # Application entry point
├── templates/          # Askama HTML templates
├── migrations/         # Database migrations
├── assets/
│   ├── js/            # TypeScript/JavaScript files
│   ├── styles/        # CSS files
│   └── dist/          # Built assets (auto-generated)
├── flake.nix          # Nix development environment
├── build.rs           # Build script for assets
├── justfile           # Task runner commands
└── README.md
```

## Development Workflow

1. **Make changes** to Rust code, templates, or assets
2. **Auto-reload** is enabled in development mode
3. **Assets are rebuilt** automatically when frontend files change
4. **Database migrations** are applied automatically on startup

## Adding Features

### Adding a New Page

1. Create a template in `templates/`
2. Add a handler in `src/handlers/`
3. Add a route in `src/lib.rs`

### Adding Database Tables

1. Create a migration: `just migrate-create table_name`
2. Edit the migration file in `migrations/`
3. Add a model in `src/models/`
4. Run migrations: `just migrate`

### Customizing Styles

1. Edit `assets/styles/input.css`
2. Modify `tailwind.config.js` for theme customization
3. Assets rebuild automatically in development

## Deployment

1. **Build for production:**
   ```bash
   just build
   ```

2. **Set environment variables** for production
3. **Run the binary:**
   ```bash
   ./target/release/rust-web-shell
   ```

## License

This project is available as a template. Use it as the foundation for your own projects.