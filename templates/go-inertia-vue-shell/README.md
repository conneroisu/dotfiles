# Go + Inertia.js + Vue Development Shell

A Nix development shell for building full-stack applications with Go backend and Vue 3 frontend using Inertia.js.

## Quick Start

1. Enter the development shell:
   ```bash
   nix develop
   ```

2. Initialize the project:
   ```bash
   setup
   ```

3. Copy example files to get started:
   ```bash
   cp main.go.example main.go
   cp package.json.example package.json
   ```

4. Install dependencies:
   ```bash
   go mod tidy
   bun install
   ```

5. Run development servers:
   ```bash
   dev
   ```

   This will start:
   - Go server with hot-reload (using Air) on http://localhost:8080
   - Vite dev server for Vue

## Project Structure

```
.
├── main.go                 # Go server entry point
├── go.mod                  # Go module file
├── package.json            # Node.js dependencies
├── vite.config.js          # Vite configuration
├── .air.toml              # Air hot-reload configuration
├── resources/
│   ├── views/
│   │   └── root.html      # Inertia root template
│   └── js/
│       ├── app.js         # Vue app entry point
│       ├── Pages/         # Inertia page components
│       │   ├── Home.vue
│       │   ├── About.vue
│       │   └── Contact.vue
│       └── Components/    # Shared Vue components
│           └── Layout.vue
└── public/
    └── build/             # Built assets (generated)
```

## Available Commands

- `setup` - Initialize Go module and install dependencies
- `dev` - Run development servers (Go + Vite)
- `build` - Build for production
- `dx` - Edit flake.nix
- `gx` - Edit go.mod
- `px` - Edit package.json
- `vx` - Edit vite.config.js

## Features

- Hot-reload for both Go and Vue code
- Inertia.js for seamless SPA experience
- Vue 3 Composition API with `<script setup>`
- TypeScript support
- Bun for fast JavaScript runtime and package management
- Vite for fast frontend builds
- Air for Go hot-reloading
- Vue Language Server for enhanced DX
- shadcn-vue component library with Tailwind CSS
- bun2nix integration for Nix package builds

## Package Building

This template includes bun2nix integration for building Nix packages:

```bash
# Build the frontend package
nix build .#frontend

# Build the complete application (Go + frontend)
nix build

# Development shell with bun2nix
nix develop
```

The `postinstall` script automatically runs `bun2nix -o bun.nix` to keep dependency files up to date.

## Learn More

- [Inertia.js Documentation](https://inertiajs.com/)
- [Gonertia Documentation](https://github.com/romsar/gonertia)
- [Vue 3 Documentation](https://vuejs.org/)
- [Vite Documentation](https://vitejs.dev/)