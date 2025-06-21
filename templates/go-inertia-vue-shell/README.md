# Go + Inertia.js + Vue Development Shell

A Nix development shell for building full-stack applications with Go backend and Vue 3 frontend using Inertia.js with Shadcn UI components.

## Quick Start

1. Enter the development shell:
   ```bash
   nix develop
   ```

2. Install dependencies and build frontend:
   ```bash
   bun install
   bun run build
   ```

3. Run the server:
   ```bash
   go run main.go
   ```

   Or for development with hot-reload:
   ```bash
   dev  # Runs both Go (with air) and Vite dev server
   ```

   The application will be available at http://localhost:8081

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

- `dev` - Run development servers (Go with air + Vite)
- `build` - Build frontend assets for production
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

## Running with Nix

To run the application with `nix run`:

```bash
# First ensure frontend assets are built
bun install
bun run build

# Then run the application
nix run .
```

**Note**: The `nix run` command requires pre-built frontend assets in the `public/build` directory.

## Learn More

- [Inertia.js Documentation](https://inertiajs.com/)
- [Gonertia Documentation](https://github.com/romsar/gonertia)
- [Vue 3 Documentation](https://vuejs.org/)
- [Vite Documentation](https://vitejs.dev/)